//
//  VedioPlayerViewController.m
//  VedioPlayer
//
//  Created by yanghuang on 2017/11/22.
//  Copyright © 2017年 com.yang. All rights reserved.
//

#import "VedioPlayerViewController.h"
#import "VedioPlayerView.h"

static const CGFloat animationTimeinterval = 0.3f;

@interface VedioPlayerViewController ()<ProgressSliderDelegate>

@property (nonatomic, strong) VedioPlayerView *videoView;
@property (nonatomic, strong) UIView *vedioBackgroundView;

//文件模型
@property (nonatomic, strong) VedioModel *vedioModel;

@property (nonatomic, assign) CGRect originFrame;

@property (nonatomic, strong) NSTimer *durationTimer;

@property (nonatomic, assign) BOOL isFullscreenMode;

//VedioView状态
/*
 * 是否处于seek阶段/seek中间会存在一个不同步问题
 * 所以在seek中间不处理 addPeriodicTimeObserverForInterval
 */
@property (nonatomic, assign) BOOL isSeeking;
//是否拖拽中
@property (nonatomic, assign) BOOL isDragging;
//播放状态
@property (nonatomic, assign) VedioStatus playerStatus;
//总播放时长
@property (nonatomic, assign) CGFloat totalTime;

@property (nonatomic, strong) id timeObserver;

@property (nonatomic, strong) AVPlayerItem *playerItem;
@end

@implementation VedioPlayerViewController

-(void)dealloc {
    //remove监听
    [self destroyPlayer];
    [self removeObserver:self forKeyPath:@"playerStatus"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, 200);
        self.view.backgroundColor = [UIColor blackColor];
        [self.view addSubview:self.videoView];
        self.videoView.frame = self.view.bounds;
        self.playerStatus = VedioStatusPause;
        self.videoView.timeSlider.delegate = self;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super init];
    if (self) {
        self.view.frame = frame;
        self.view.backgroundColor = [UIColor blackColor];
        [self.view addSubview:self.videoView];
        self.videoView.frame = self.view.bounds;
        self.playerStatus = VedioStatusPause;
        self.videoView.timeSlider.delegate = self;
        [self.videoView.playButton addTarget:self action:@selector(playButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.videoView.landscapeButton addTarget:self action:@selector(fullScreenButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)show
{
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    if (!keyWindow) {
        keyWindow = [[[UIApplication sharedApplication] windows] firstObject];
    }
    [keyWindow addSubview:self.view];
    self.view.alpha = 0.0;
    [UIView animateWithDuration:animationTimeinterval animations:^{
        self.view.alpha = 1.0;
    } completion:^(BOOL finished) {
        
    }];
}

-(void)dismiss {
//    [self stopDurationTimer];
//    [self stop];
    [UIView animateWithDuration:animationTimeinterval animations:^{
        self.view.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
        if (self.dimissCompleteBlock) {
            self.dimissCompleteBlock();
        }
    }];
}


- (void)startWithModel:(VedioModel *)model {
    self.vedioModel = model;
    self.videoView.thumbnailImageView.image = [VedioPlayerConfig getThumbnailImage:model.contentURL];
    [self initPlayer];
}

#pragma mark 初始化播放文件，只允许在播放按钮事件使用
- (void)initPlayer {
    [self initPlayerItem];
    [self addPlayerListener];
}

//修改playerItem
- (void)initPlayerItem {
    if (self.vedioModel && self.vedioModel.contentURL) {
        self.playerItem = [AVPlayerItem playerItemWithURL:self.vedioModel.contentURL];
        [self.videoView.player replaceCurrentItemWithPlayerItem:self.playerItem];
        
    }
}

//添加监听文件,所有的监听
- (void)addPlayerListener {
    
    //自定义播放状态监听
    [self addObserver:self forKeyPath:@"playerStatus" options:NSKeyValueObservingOptionNew context:nil];
    if (self.videoView.player) {
        //播放速度监听
        [self.videoView.player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:nil];
    }
    
    if (self.playerItem) {
        //播放状态监听
        [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        //缓冲进度监听
        [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
        
        //播放中监听，更新播放进度
        __weak typeof(self) weakSelf = self;
        self.timeObserver = [self.videoView.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 30) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            if (time.value > 0) {
                weakSelf.videoView.thumbnailImageView.alpha = 0.0;
            }
            float currentPlayTime = (double)weakSelf.playerItem.currentTime.value/weakSelf.playerItem.currentTime.timescale;
            if (weakSelf.playerItem.currentTime.value<0) {
                currentPlayTime = 0.1; //防止出现时间计算越界问题
            }
            //拖拽期间不更新数据
            if (!weakSelf.isDragging) {
                weakSelf.videoView.timeSlider.value = currentPlayTime;
                weakSelf.videoView.timeLabel.text = [NSString stringWithFormat:@"%@/%@",[VedioPlayerConfig convertTime:currentPlayTime],[VedioPlayerConfig convertTime:weakSelf.totalTime]];
            }
        }];
        
    }
    
    //给AVPlayerItem添加播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    //监听应用后台切换
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appEnteredBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    //播放中被打断
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInterruption:) name:AVAudioSessionInterruptionNotification object:[AVAudioSession sharedInstance]];
    //拔掉耳机监听？？
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeviceOrientationChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil
     ];
}

- (void)onDeviceOrientationChange{
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    UIInterfaceOrientation interfaceOrientation = (UIInterfaceOrientation)orientation;
    switch (interfaceOrientation) {
            /**        case UIInterfaceOrientationUnknown:
             NSLog(@"未知方向");
             break;
             */
        case UIInterfaceOrientationPortraitUpsideDown:{
            NSLog(@"第3个旋转方向---电池栏在下");
            [self backOrientationPortrait];
        }
            break;
        case UIInterfaceOrientationPortrait:{
            NSLog(@"第0个旋转方向---电池栏在上");
            [self backOrientationPortrait];
        }
            break;
        case UIInterfaceOrientationLandscapeLeft:{
            NSLog(@"第2个旋转方向---电池栏在右");
            [self setDeviceOrientationLandscapeLeft];
        }
            break;
        case UIInterfaceOrientationLandscapeRight:{
            NSLog(@"第1个旋转方向---电池栏在左");
            [self setDeviceOrientationLandscapeRight];
        }
            break;
            
        default:
            break;
    }
    
}

- (void)fullScreenButtonClick
{
    if (self.isFullscreenMode) {
        [self backOrientationPortrait];
    } else {
        
        [self setDeviceOrientationLandscapeRight];
    }
}

- (void)shrinkScreenButtonClick
{
    if (!self.isFullscreenMode) {
        return;
    }
    
    [self backOrientationPortrait];
    
}

//返回小屏幕
- (void)backOrientationPortrait{
    if (!self.isFullscreenMode) {
        return;
    }
    [UIView animateWithDuration:animationTimeinterval animations:^{
        [self.view setTransform:CGAffineTransformIdentity];
        self.frame = self.originFrame;
    } completion:^(BOOL finished) {
        self.isFullscreenMode = NO;
        if (self.willChangeToSmallscreenMode) {
            self.willChangeToSmallscreenMode();
        }
    }];
}

//电池栏在左全屏
- (void)setDeviceOrientationLandscapeRight{
    if (self.isFullscreenMode) {
        return;
    }
    
    self.originFrame = self.view.frame;
    CGFloat height = [[UIScreen mainScreen] bounds].size.width;
    CGFloat width = [[UIScreen mainScreen] bounds].size.height;
    CGRect frame = CGRectMake((height - width) / 2, (width - height) / 2, width, height);;
    [UIView animateWithDuration:animationTimeinterval animations:^{
        self.frame = frame;
        [self.view setTransform:CGAffineTransformMakeRotation(M_PI_2)];
    } completion:^(BOOL finished) {
        self.isFullscreenMode = YES;
        if (self.willChangeToFullscreenMode) {
            self.willChangeToFullscreenMode();
        }
    }];
    
}
//电池栏在右全屏
- (void)setDeviceOrientationLandscapeLeft{

    if (self.isFullscreenMode) {
        return;
    }
    self.originFrame = self.view.frame;
    CGFloat height = [[UIScreen mainScreen] bounds].size.width;
    CGFloat width = [[UIScreen mainScreen] bounds].size.height;
    CGRect frame = CGRectMake((height - width) / 2, (width - height) / 2, width, height);;
    [UIView animateWithDuration:animationTimeinterval animations:^{
        self.frame = frame;
        [self.view setTransform:CGAffineTransformMakeRotation(-M_PI_2)];
    } completion:^(BOOL finished) {
        self.isFullscreenMode = YES;
        if (self.willChangeToFullscreenMode) {
            self.willChangeToFullscreenMode();
        }
    }];
}

//销毁player,无奈之举 因为avplayeritem的制空后依然缓存的问题。
- (void)destroyPlayer {
    
    [self.playerItem removeObserver:self forKeyPath:@"status"];
    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.videoView.player removeObserver:self forKeyPath:@"rate"];
    [self.videoView.player removeTimeObserver:self.timeObserver];
    
    self.playerItem = nil;
    self.videoView.player = nil;
    
    self.playerStatus = VedioStatusPause;
    self.videoView.timeSlider.value = 0;
    self.videoView.timeLabel.text = [NSString stringWithFormat:@"00:00:00/%@",[VedioPlayerConfig convertTime:_totalTime]];
}

- (void)changeModel:(VedioModel *)vedioModel {
    if (vedioModel && vedioModel.musicURL) {
        if (self.playerItem && self.videoView.player) {
            [self destroyPlayer];
            self.vedioModel = vedioModel;
        }
    } else {
        [self pause];
    }
}

#pragma mark 播放，暂停
- (void)play{
    if (self.videoView.player && self.playerStatus == VedioStatusPause) {
        NSLog(@"通过播放停止");
        self.playerStatus = VedioStatusBuffering;
        [self.videoView.player play];
    }
}

- (void)pause{
    if (self.videoView.player && self.playerStatus != VedioStatusPause) {
        NSLog(@"通过暂停停止");
        self.playerStatus = VedioStatusPause;
        [self.videoView.player pause];
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

#pragma mark 监听捕获
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"status"]) {
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
        AVPlayerItem *item = (AVPlayerItem *)object;
        NSArray * array = item.loadedTimeRanges;
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue]; //本次缓冲的时间范围
        NSTimeInterval totalBuffer = CMTimeGetSeconds(timeRange.start) + CMTimeGetSeconds(timeRange.duration); //缓冲总长度
        self.videoView.timeSlider.trackValue = totalBuffer;
        //当缓存到位后开启播放，取消loading
        if (totalBuffer >self.videoView.timeSlider.value && self.playerStatus != VedioStatusPause) {
            [self.videoView.player play];
        }
        NSLog(@"---共缓冲---%.2f",totalBuffer);
    } else if ([keyPath isEqualToString:@"rate"]){
        AVPlayer *item = (AVPlayer *)object;
        if (item.rate == 0) {
            if (self.playerStatus != VedioStatusPause) {
                self.playerStatus = VedioStatusBuffering;
            }
        } else {
            self.playerStatus = VedioStatusPlaying;
            
        }
        NSLog(@"---播放速度---%f",item.rate);
    } else if([keyPath isEqualToString:@"playerStatus"]){
        switch (self.playerStatus) {
            case VedioStatusBuffering:
                [self.videoView.timeSlider.sliderBtn showActivity:YES];
                break;
            case VedioStatusPause:
                [self.videoView.playButton setImage:[UIImage imageNamed:@"video-play"] forState:UIControlStateNormal];
                [self.videoView.timeSlider.sliderBtn showActivity:NO];
                break;
            case VedioStatusPlaying:
                [self.videoView.playButton setImage:[UIImage imageNamed:@"video-pause"] forState:UIControlStateNormal];
                [self.videoView.timeSlider.sliderBtn showActivity:NO];
                break;
                
            default:
                break;
        }
    }
}

#pragma mark 监听拖拽事件,拖拽中、拖拽开始、拖拽结束

// 开始拖动
- (void)beiginSliderScrubbing {
    self.isDragging = YES;
}

// 拖动值发生改变
- (void)sliderScrubbing {
    if (self.totalTime != 0) {
        self.videoView.timeLabel.text = [NSString stringWithFormat:@"%@/%@",[VedioPlayerConfig convertTime:self.videoView.timeSlider.value],[VedioPlayerConfig convertTime:_totalTime]];
    }
}

// 结束拖动
- (void)endSliderScrubbing {
    self.isDragging = NO;
    CMTime time = CMTimeMake(self.videoView.timeSlider.value, 1);
    
    self.videoView.timeLabel.text = [NSString stringWithFormat:@"%@/%@",[VedioPlayerConfig convertTime:self.videoView.timeSlider.value],[VedioPlayerConfig convertTime:_totalTime]];
    if (self.playerStatus != VedioStatusPause) {
        [self.videoView.player pause];
        [self.playerItem seekToTime:time completionHandler:^(BOOL finished) {
            [self.videoView.player play];
            self.playerStatus = VedioStatusBuffering; //结束拖动后处于一个缓冲状态?如果直接拖到结束呢？
        }];
    }
}

#pragma mark 播放按钮事件
- (void)playButtonAction:(id)sender {
    if (self.videoView.player) {
        if (self.playerStatus == VedioStatusPause) {
            [self play];
        } else {
            [self pause];
        }
    } else {
        [self initPlayer];
        [self play];
    }
}

#pragma mark 设置时间轴最大时间
- (void)setMaxDuratuin:(float)duration{
    _totalTime = duration;
    self.videoView.timeSlider.maximumValue = duration;
    self.videoView.timeLabel.text = [NSString stringWithFormat:@"00:00:00/%@",[VedioPlayerConfig convertTime:duration]];
}

- (VedioPlayerView *)videoView {
    if (!_videoView) {
        _videoView = [[VedioPlayerView alloc]init];
    }
    return _videoView;
}

- (UIView *)vedioBackgroundView {
    if (!_vedioBackgroundView) {
        _vedioBackgroundView = [[UIView alloc]init];
        _vedioBackgroundView.alpha = 0.0;
        _vedioBackgroundView.backgroundColor = [UIColor blackColor];
    }
    return _vedioBackgroundView;
}

- (void)setFrame:(CGRect)frame {
    [self.view setFrame:frame];
    [self.videoView setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    [self.videoView setNeedsLayout];
    [self.videoView layoutIfNeeded];
}

@end
