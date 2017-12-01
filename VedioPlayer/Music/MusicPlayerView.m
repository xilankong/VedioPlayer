//
//  MusicPlayerView.m
//  VedioPlayer
//
//  Created by yanghuang on 2017/5/27.
//  Copyright © 2017年 com.yang. All rights reserved.
//

#import "MusicPlayerView.h"
#import <Masonry/Masonry.h>

@interface MusicPlayerView ()<ProgressSliderDelegate>

@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic, strong) UILabel *timeNowLabel;

@property (nonatomic, strong) UILabel *timeTotalLabel;

@property (nonatomic, strong) UIButton *playButton;

@property (nonatomic, strong) ProgressSlider *timeSlider;

@property (nonatomic, strong) AVPlayerItem *playerItem;
//播放状态
@property (nonatomic, assign) VedioStatus playerStatus;
//文件模型
@property (nonatomic, strong) VedioModel *musicModel;
/*
 * 是否处于seek阶段/seek中间会存在一个不同步问题
 * 所以在seek中间不处理 addPeriodicTimeObserverForInterval
 */
@property (nonatomic, assign) BOOL isSeeking;
//是否拖拽中
@property (nonatomic, assign) BOOL isDragging;
//总播放时长
@property (nonatomic, assign) CGFloat totalTime;

@property (nonatomic, strong) id timeObserver;
@end


@implementation MusicPlayerView

- (void)dealloc
{
    [self destroyPlayer];
    [self removeObserver:self forKeyPath:@"playerStatus"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark 初始化组件\初始化playerListener

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.frame = CGRectMake(0, 0, SCREEN_WIDTH, toolBarHeight);
        [self initUI];
    }
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initUI];
    }
    return self;
}

- (void)initUI {
    
    self.backgroundColor = [[UIColor blackColor]colorWithAlphaComponent:0.5];
    
    [self addSubview:self.playButton];
    [self addSubview:self.timeNowLabel];
    [self addSubview:self.timeSlider];
    [self addSubview:self.timeTotalLabel];
    
    [self.playButton setImage:playImage forState:UIControlStateNormal];
    [self.playButton addTarget:self action:@selector(playButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    __weak typeof(self) weakself = self;
    [self.playButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(weakself).offset(5);
        make.centerY.equalTo(weakself);
        make.width.mas_equalTo(toolBarHeight * 0.8);
        make.height.mas_equalTo(toolBarHeight * 0.8);
    }];
    
    [self.timeNowLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(weakself.playButton.mas_trailing).offset(5);
        make.top.bottom.equalTo(weakself);
    }];
    

    [self.timeTotalLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(weakself).offset(-15);
        make.top.bottom.equalTo(weakself);
    }];
    
    [self.timeSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(weakself.timeNowLabel.mas_trailing).offset(5);
        make.top.bottom.equalTo(weakself);
        make.trailing.equalTo(self.timeTotalLabel.mas_leading).offset(-5);
    }];
    [self.timeSlider setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    
}

- (void)setUpWithModel:(VedioModel *)model {
    self.musicModel = model;
    [self initMusic];
}

#pragma mark 初始化播放文件，只允许在播放按钮事件使用
- (void)initMusic {
    
    [self.timeSlider showActivity:YES];
    self.player = [[AVPlayer alloc]init];
    [self initPlayerItem];
    [self addPlayerListener];
    [self addPlayerItemListener];
}

//修改playerItem
- (void)initPlayerItem {
    if (self.musicModel && self.musicModel.contentURL) {
        
        self.playerItem = [AVPlayerItem playerItemWithURL:self.musicModel.contentURL];
        [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
    }
}

//添加监听文件,所有的监听
- (void)addPlayerListener {
    
    //自定义播放状态监听
    [self addObserver:self forKeyPath:@"playerStatus" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    if (self.player) {
        //播放速度监听
        [self.player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    }
    //播放中监听，更新播放进度
    __weak typeof(self) weakSelf = self;
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 30) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        float currentPlayTime = (double)weakSelf.playerItem.currentTime.value/weakSelf.playerItem.currentTime.timescale;
        if (weakSelf.playerItem.currentTime.value<0) {
            currentPlayTime = 0.1; //防止出现时间计算越界问题
        }
        //拖拽期间不更新数据
        if (!weakSelf.isDragging && weakSelf.playerStatus != VedioStatusBuffering) {
            weakSelf.timeSlider.value = currentPlayTime;
            if (isnan(currentPlayTime)) {
                currentPlayTime = 0;
            }
            [weakSelf updateTimeWithTimeNow:currentPlayTime];
        }
    }];
    
    //给AVPlayerItem添加播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    //监听应用后台切换
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appEnteredBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    //播放中被打断
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInterruption:) name:AVAudioSessionInterruptionNotification object:[AVAudioSession sharedInstance]];
    //拔掉耳机监听
}
#pragma mark 播放对象监听、缓冲值，播放状态
- (void)addPlayerItemListener {
    if (self.playerItem) {
        //播放状态监听
        [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
        //缓冲进度监听
        [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    }
    
}

#pragma mark 监听捕获
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    int new = (int)[change objectForKey:@"new"];
    int old = (int)[change objectForKey:@"old"];
    if ([keyPath isEqualToString:@"status"]) {
        if (new == old) {
            return;
        }
        AVPlayerItem *item = (AVPlayerItem *)object;
        if ([self.playerItem status] == AVPlayerStatusReadyToPlay) {
            //获取音频总长度
            CMTime duration = item.duration;
            [self setMaxDuratuin:CMTimeGetSeconds(duration)];
            NSLog(@"AVPlayerStatusReadyToPlay -- 音频时长%f",CMTimeGetSeconds(duration));
            
        }else if([self.playerItem status] == AVPlayerStatusFailed) {
            
            [self playerFailed];
            NSLog(@"AVPlayerStatusFailed -- 播放异常");
            
        }else if([self.playerItem status] == AVPlayerStatusUnknown) {
            
            [self pause];
            NSLog(@"AVPlayerStatusUnknown -- 未知原因停止");
        }
    } else if([keyPath isEqualToString:@"loadedTimeRanges"]) {
        NSArray * array = ((AVPlayerItem *)object).loadedTimeRanges;
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];
        NSTimeInterval totalBuffer = CMTimeGetSeconds(timeRange.start) + CMTimeGetSeconds(timeRange.duration);
        self.timeSlider.bufferValue = totalBuffer;
        //当缓存到位后开启播放，取消loading
        if (totalBuffer >self.timeSlider.value && self.playerStatus != VedioStatusPause) {
            [self play];
        }
        NSLog(@"---共缓冲---%.2f",totalBuffer);
    } else if ([keyPath isEqualToString:@"rate"]){
        if (new == old) {
            return;
        }
        AVPlayer *item = (AVPlayer *)object;
        if (item.rate == 0 && self.playerStatus != VedioStatusPause) {
            self.playerStatus = VedioStatusBuffering;
        } else if (item.rate == 1) {
            self.playerStatus = VedioStatusPlaying;
            
        }
        NSLog(@"---播放速度---%f",item.rate);
    } else if([keyPath isEqualToString:@"playerStatus"]){
        if (new == old) {
            return;
        }
        switch (self.playerStatus) {
            case VedioStatusBuffering:
                [self.timeSlider showActivity:YES];
                break;
            case VedioStatusPause:
                [self.playButton setImage:[UIImage imageNamed:@"video-play"] forState:UIControlStateNormal];
                [self.timeSlider showActivity:NO];
                break;
            case VedioStatusPlaying:
                [self.playButton setImage:[UIImage imageNamed:@"video-pause"] forState:UIControlStateNormal];
                [self.timeSlider showActivity:NO];
                break;
                
            default:
                break;
        }
    }
}

//销毁playerItem
- (void)destroyPlayerItem {
    if (self.playerItem) {
        [self.playerItem removeObserver:self forKeyPath:@"status"];
        [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        self.playerItem = nil;
        self.playerStatus = VedioStatusPause;
        [self.player replaceCurrentItemWithPlayerItem:nil];
    }
}

//销毁player
- (void)destroyPlayer {

    [self destroyPlayerItem];
    [self.player removeObserver:self forKeyPath:@"rate"];
    [self.player removeTimeObserver:self.timeObserver];
    
    self.player = nil;
    self.timeSlider.value = 0;
    self.timeSlider.bufferValue = 0;
    self.timeNowLabel.text = @"00:00";
}

- (void)changeMusicWithModel:(VedioModel *)musicModel {
    if (musicModel && musicModel.contentURL) {
        if (self.playerItem && self.player) {
            [self destroyPlayerItem];
            self.musicModel = musicModel;
        }
    } else {
        [self pause];
    }
}

#pragma mark 播放, 暂停, 停止
- (void)play{
    if (self.player && self.playerStatus == VedioStatusPause) {
        NSLog(@"通过播放开始");
        self.playerStatus = VedioStatusBuffering;
        [self.player play];
    }
}

- (void)pause{
    if (self.player && self.playerStatus != VedioStatusPause) {
        NSLog(@"通过暂停停止");
        self.playerStatus = VedioStatusPause;
        [self.player pause];
    }
}

#pragma mark 播放按钮事件
- (void)playButtonAction:(id)sender {
    if (self.playerItem) {
        if (self.playerStatus == VedioStatusPause) {
            [self play];
        } else {
            [self pause];
        }
    } else {
        [self initMusic];
        [self play];
    }
}
#pragma mark 监听播放完成事件
-(void)playerFinished:(NSNotification *)notification{
    NSLog(@"播放完成");
    [self.playerItem seekToTime:kCMTimeZero];
    [self pause];
}

#pragma mark 播放失败
-(void)playerFailed{
    NSLog(@"播放失败");
    [self destroyPlayer];
}

#pragma mark 播放被打断
- (void)handleInterruption:(NSNotification *)notification {
    [self pause];
}

#pragma mark 进入后台，暂停音频
- (void)appEnteredBackground {
    [self pause];
}


#pragma mark 更新时间轴
- (void)updateTimeWithTimeNow:(CGFloat)timeNow {
    int time = round(timeNow);
    self.timeNowLabel.text = [VedioPlayerConfig convertTime:time];
}


#pragma mark 监听拖拽事件,拖拽中、拖拽开始、拖拽结束

// 开始拖动
- (void)beiginSliderScrubbing {
    self.isDragging = YES;
}

// 拖动值发生改变
- (void)sliderScrubbing {
    if (self.totalTime != 0) {
        [self updateTimeWithTimeNow:self.timeSlider.value];
    }
}

// 结束拖动
- (void)endSliderScrubbing {
    self.isDragging = NO;
    CMTime time = CMTimeMake(self.timeSlider.value, 1);
    [self updateTimeWithTimeNow:self.timeSlider.value];
    if (self.playerStatus != VedioStatusPause) {
        [self.player pause];
        [self.playerItem seekToTime:time completionHandler:^(BOOL finished) {
            self.playerStatus = VedioStatusBuffering; //结束拖动后处于一个缓冲状态?如果直接拖到结束呢？
            [self.player play];
        }];
    }
}

#pragma mark 设置时间轴最大时间、初始化历史播放进度
- (void)setMaxDuratuin:(float)duration{
    //设置时间轴最大时间
    _totalTime = duration;
    self.timeSlider.maximumValue = duration;
    self.timeTotalLabel.text = [VedioPlayerConfig convertTime:duration];
    //初始化历史播放进度
    CGFloat value = self.musicModel.progress >=  100 ? 0 : round((self.musicModel.progress / 100.0) * 10000) / 10000;
    self.timeSlider.value = value * _totalTime;
    [self updateTimeWithTimeNow:self.timeSlider.value];
    
    CMTime time = CMTimeMake(self.timeSlider.value, 1);
    __weak typeof(self) weakself = self;
    [self.playerItem seekToTime:time completionHandler:^(BOOL finished) {
        [weakself pause];
        [weakself.timeSlider showActivity:NO];
    }];
    //固定timeLabel的宽度
    [self.timeTotalLabel sizeToFit];
    [self.timeTotalLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(weakself.timeTotalLabel.frame.size.width + 5);
    }];
    [self.timeNowLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(weakself.timeTotalLabel.frame.size.width + 5);
    }];
}

- (UILabel *)timeNowLabel {
    if (!_timeNowLabel) {
        _timeNowLabel = [[UILabel alloc]init];
        _timeNowLabel.textColor = [UIColor whiteColor];
        _timeNowLabel.font = [UIFont systemFontOfSize:13];
        _timeNowLabel.textAlignment = NSTextAlignmentLeft;
        _timeNowLabel.text = @"00:00";
    }
    return _timeNowLabel;
}

-(UILabel *)timeTotalLabel {
    if (!_timeTotalLabel) {
        _timeTotalLabel = [[UILabel alloc]init];
        _timeTotalLabel.textColor = [UIColor whiteColor];
        _timeTotalLabel.font = [UIFont systemFontOfSize:13];
        _timeTotalLabel.text = @"00:00";
        _timeTotalLabel.textAlignment = NSTextAlignmentRight;
    }
    return _timeTotalLabel;
}

- (UIButton *)playButton {
    if (!_playButton) {
        _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    }
    return _playButton;
}

- (ProgressSlider *)timeSlider {
    if (!_timeSlider) {
        _timeSlider = [[ProgressSlider alloc]init];
        _timeSlider.delegate = self;
        _timeSlider.sliderDotDiameter = 14;
        _timeSlider.playProgressColor = [[UIColor redColor]colorWithAlphaComponent:0.7];
    }
    return _timeSlider;
}
@end
