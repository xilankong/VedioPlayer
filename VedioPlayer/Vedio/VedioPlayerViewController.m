//
//  VedioPlayerViewController.m
//  VedioPlayer
//
//  Created by yanghuang on 2017/11/22.
//  Copyright © 2017年 com.yang. All rights reserved.
//

#import "VedioPlayerViewController.h"

//VedioView状态
/*
 * 全局时间单位精度为 秒
 */
static const CGFloat animationTimeinterval = 0.3f;

@interface VedioPlayerViewController ()<ProgressSliderDelegate>

@property (nonatomic, strong) AVPlayer *player;
//播放模型
@property (nonatomic, strong) AVPlayerItem *playerItem;
//播放UI
@property (nonatomic, strong) VedioPlayerView *videoView;
//文件模型
@property (nonatomic, strong) VedioModel *vedioModel;
//播放状态
@property (nonatomic, assign) VedioStatus playerStatus;

//VedioView状态
/*
 * 是否处于seek阶段/seek中间会存在一个不同步问题
 * 所以在seek中间不处理 addPeriodicTimeObserverForInterval
 */
@property (nonatomic, assign) BOOL isSeeking;
//是否拖拽中
@property (nonatomic, assign) BOOL isDragging;
//全屏状态
@property (nonatomic, assign) BOOL isFullscreenMode;
//总播放时长
@property (nonatomic, assign) CGFloat totalTime;
//frame持有
@property (nonatomic, assign) CGRect originFrame;
//监听者
@property (nonatomic, strong) id timeObserver;

@end

@implementation VedioPlayerViewController

#pragma mark 销毁
-(void)dealloc {
    //remove监听 销毁播放对象
    [self destroyPlayer];
    
    [self removeObserver:self forKeyPath:@"playerStatus"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark 初始化方法
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH * (9.0/16.0));
        [self initUI];
        [self initControlAction];
        [self addPlayerListener];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super init];
    if (self) {
        self.view.frame = frame;
        [self initUI];
        [self initControlAction];
        [self addPlayerListener];
    }
    return self;
}

#pragma mark 初始化基础UI
- (void)initUI {
    self.view.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.videoView];
    self.videoView.frame = self.view.bounds;
    self.videoView.timeSlider.delegate = self;
    self.player = [[AVPlayer alloc]init];
    [(AVPlayerLayer *)self.videoView.layer setPlayer:self.player];
    
    self.playerStatus = VedioStatusPause;
    [self.videoView showLoadingView:YES];
    self.videoView.centerPlayButton.hidden = YES;
}

#pragma mark 初始化控件事件
- (void)initControlAction {
    
    //工具条按钮暂停、开始
    [self.videoView.playButton addTarget:self action:@selector(playButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    //中间按钮暂停、开始
    [self.videoView.centerPlayButton addTarget:self action:@selector(playButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    //横屏
    [self.videoView.landscapeButton addTarget:self action:@selector(fullScreenButtonClick) forControlEvents:UIControlEventTouchUpInside];
    //双击暂停、开始
    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTapAction:)];
    doubleTapGesture.numberOfTapsRequired = 2;
    doubleTapGesture.numberOfTouchesRequired = 1;
    [self.videoView.controlView addGestureRecognizer:doubleTapGesture];
}

#pragma mark 设置数据源
- (void)setUpWithModel:(VedioModel *)model {
    self.vedioModel = model;
    self.videoView.thumbnailImageView.image = [VedioPlayerConfig getThumbnailImage:model.contentURL];
    [self initPlayer];
}

#pragma mark 初始化播放文件，只允许在播放按钮事件使用
- (void)initPlayer {
    [self initPlayerItem];
    [self addPlayerItemListener];
}

#pragma mark 初始化playerItem
- (void)initPlayerItem {
    if (self.vedioModel && self.vedioModel.contentURL) {
        self.playerItem = [AVPlayerItem playerItemWithURL:self.vedioModel.contentURL];
        [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
    }
}

#pragma mark 播放速度、播放状态、播放进度、后台等用户操作、横竖屏监听
- (void)addPlayerListener {
    //自定义播放状态监听
    [self addObserver:self forKeyPath:@"playerStatus" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    if (self.player) {
        //播放速度监听
        [self.player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
        
        //播放中监听，更新播放进度
        __weak typeof(self) weakself = self;
        self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 30) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            float currentPlayTime = (double)weakself.playerItem.currentTime.value/weakself.playerItem.currentTime.timescale;
            if (weakself.playerItem.currentTime.value<0) {
                currentPlayTime = 0.1; //防止出现时间计算越界问题
            }
            //拖拽期间不更新数据
            if (!weakself.isDragging && weakself.playerStatus != VedioStatusBuffering) {
                if (currentPlayTime > 0 && weakself.videoView.thumbnailImageView.alpha > 0) {
                    weakself.videoView.thumbnailImageView.alpha = 0.0;
                }
                weakself.videoView.timeSlider.value = currentPlayTime;
                if (isnan(currentPlayTime)) {
                    currentPlayTime = 0;
                }
                [weakself updateTimeWithTimeNow:currentPlayTime andTotalTime:weakself.totalTime];
            }
        }];
    }
    
    //播放完成通知监听
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    //监听应用后台切换
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appEnteredBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    //播放中被打断
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInterruption:) name:AVAudioSessionInterruptionNotification object:[AVAudioSession sharedInstance]];
    
    //横竖屏监听
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeviceOrientationChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
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
    if ([keyPath isEqualToString:@"status"]) {     //播放状态
        if (new == old) {
            return;
        }
        AVPlayerItem *item = (AVPlayerItem *)object;
        if ([self.playerItem status] == AVPlayerStatusReadyToPlay) {
            //获取音频总长度
            CMTime duration = item.duration;
            [self setMaxDuratuin:CMTimeGetSeconds(duration)];
        } else if([self.playerItem status] == AVPlayerStatusFailed) {
            //播放异常
            [self playerFailed];
        } else if([self.playerItem status] == AVPlayerStatusUnknown) {
            //未知原因停止
            [self pause];
        }
    } else if([keyPath isEqualToString:@"loadedTimeRanges"]) { //缓冲进度
        NSArray * array = ((AVPlayerItem *)object).loadedTimeRanges;
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];
        NSTimeInterval totalBuffer = CMTimeGetSeconds(timeRange.start) + CMTimeGetSeconds(timeRange.duration);
        self.videoView.timeSlider.bufferValue = totalBuffer;
        //当缓存到位后开启播放，取消loading
        if (totalBuffer >self.videoView.timeSlider.value && self.playerStatus != VedioStatusPause) {
            [self play];
        }
        NSLog(@"---共缓冲---%.2f",totalBuffer);
    } else if ([keyPath isEqualToString:@"rate"]){ //播放速度
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
    } else if([keyPath isEqualToString:@"playerStatus"]){ //播放状态
        if (new == old) {
            return;
        }
        switch (self.playerStatus) {
            case VedioStatusBuffering:
                [self.videoView showLoadingView:YES];
                self.videoView.centerPlayButton.hidden = YES;
                break;
            case VedioStatusPause:
                [self.videoView.playButton setImage:[UIImage imageNamed:@"video-play"] forState:UIControlStateNormal];
                self.videoView.centerPlayButton.hidden = NO;
                [self.videoView showLoadingView:NO];
                break;
            case VedioStatusPlaying:
                [self.videoView.playButton setImage:[UIImage imageNamed:@"video-pause"] forState:UIControlStateNormal];
                self.videoView.centerPlayButton.hidden = YES;
                [self.videoView showLoadingView:NO];
                break;
                
            default:
                break;
        }
    }
}

#pragma mark 屏幕旋转、大小屏幕
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

//返回小屏幕
- (void)backOrientationPortrait{
    if (!self.isFullscreenMode) {
        return;
    }
    if (self.willChangeToSmallscreenMode) {
        self.willChangeToSmallscreenMode();
    }
    __weak typeof(self) weakself = self;
    [UIView animateWithDuration:animationTimeinterval animations:^{
        [weakself.view setTransform:CGAffineTransformIdentity];
        weakself.frame = weakself.originFrame;
    } completion:^(BOOL finished) {
        weakself.isFullscreenMode = NO;
        if (weakself.didChangeToSmallscreenMode) {
            weakself.didChangeToSmallscreenMode();
        }
    }];
}

//电池栏在左全屏
- (void)setDeviceOrientationLandscapeRight{
    if (self.isFullscreenMode) {
        return;
    }
    if (self.willChangeToFullscreenMode) {
        self.willChangeToFullscreenMode();
    }
    self.originFrame = self.view.frame;
    CGFloat height = [[UIScreen mainScreen] bounds].size.width;
    CGFloat width = [[UIScreen mainScreen] bounds].size.height;
    CGRect frame = CGRectMake((height - width) / 2, (width - height) / 2, width, height);
    __weak typeof(self) weakself = self;
    [UIView animateWithDuration:animationTimeinterval animations:^{
        weakself.frame = frame;
        [weakself.view setTransform:CGAffineTransformMakeRotation(M_PI_2)];
    } completion:^(BOOL finished) {
        weakself.isFullscreenMode = YES;
        if (weakself.didChangeToFullscreenMode) {
            weakself.didChangeToFullscreenMode();
        }
    }];
    
}
//电池栏在右全屏
- (void)setDeviceOrientationLandscapeLeft{
    
    if (self.isFullscreenMode) {
        return;
    }
    if (self.willChangeToFullscreenMode) {
        self.willChangeToFullscreenMode();
    }
    self.originFrame = self.view.frame;
    CGFloat height = [[UIScreen mainScreen] bounds].size.width;
    CGFloat width = [[UIScreen mainScreen] bounds].size.height;
    CGRect frame = CGRectMake((height - width) / 2, (width - height) / 2, width, height);
    __weak typeof(self) weakself = self;
    [UIView animateWithDuration:animationTimeinterval animations:^{
        weakself.frame = frame;
        [weakself.view setTransform:CGAffineTransformMakeRotation(-M_PI_2)];
    } completion:^(BOOL finished) {
        weakself.isFullscreenMode = YES;
        if (weakself.didChangeToFullscreenMode) {
            weakself.didChangeToFullscreenMode();
        }
    }];
}

//销毁player,无奈之举 因为avplayeritem的制空后依然缓存的问题。
#pragma mark 销毁播放item
- (void)destoryPlayerItem {
    [self pause];
    if (_playerItem) {
        [_playerItem removeObserver:self forKeyPath:@"status"];
        [_playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        _playerItem = nil;
        [_player replaceCurrentItemWithPlayerItem:nil];
    }
    
    _playerStatus = VedioStatusPause;
    _videoView.timeSlider.value = 0;
    _videoView.timeSlider.bufferValue = 0;
    [self updateTimeWithTimeNow:0 andTotalTime:_totalTime];
}

#pragma mark 销毁所有
- (void)destroyPlayer {
    [self destoryPlayerItem];
    [_player removeObserver:self forKeyPath:@"rate"];
    [_player removeTimeObserver:_timeObserver];
    _player = nil;
    _videoView = nil;
}

#pragma mark 变更源
- (void)changeModel:(VedioModel *)vedioModel {
    if (vedioModel && vedioModel.contentURL) {
        if (self.playerItem && self.player) {
            [self destoryPlayerItem];
            self.vedioModel = vedioModel;
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
        [self initPlayer];
        [self play];
    }
}

#pragma mark 双击事件
- (void)doubleTapAction:(UIGestureRecognizer *)sender {
    if (self.playerStatus == VedioStatusPlaying) {
        [self pause];
    } else {
        if (self.playerItem) {
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
}

#pragma mark 监听播放完成事件
-(void)playerFinished:(NSNotification *)notification{
    NSLog(@"播放完成");
    [self.playerItem seekToTime:kCMTimeZero];
    [self pause];
    if (self.playerFinished) {
        self.playerFinished();
    }
}

#pragma mark 播放失败
-(void)playerFailed{
    NSLog(@"播放失败");
    [self destoryPlayerItem];
}

#pragma mark 播放被打断
- (void)handleInterruption:(NSNotification *)notification {
    [self pause];
    if (self.willGoToBackground) {
        self.willGoToBackground();
    }
}

#pragma mark 进入后台，暂停音频
- (void)appEnteredBackground {
    [self pause];
    if (self.willGoToBackground) {
        self.willGoToBackground();
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
        [self updateTimeWithTimeNow:self.videoView.timeSlider.value andTotalTime:_totalTime];
    }
}

// 结束拖动
- (void)endSliderScrubbing {
    self.isDragging = NO;
    CMTime time = CMTimeMake(self.videoView.timeSlider.value, 1);
    [self updateTimeWithTimeNow:self.videoView.timeSlider.value andTotalTime:_totalTime];
    if (self.playerStatus != VedioStatusPause) {
        [self.player pause];
        __weak typeof(self) weakself = self;
        [self.playerItem seekToTime:time completionHandler:^(BOOL finished) {
            weakself.playerStatus = VedioStatusBuffering; //结束拖动后处于一个缓冲状态
            [weakself.player play];
        }];
    }
}

#pragma mark 设置时间轴最大时间
- (void)setMaxDuratuin:(CGFloat)duration {
    _totalTime = duration;
    self.videoView.timeSlider.maximumValue = duration;
    
    CGFloat value = 0;
    if (self.vedioModel.progress >=  100) {
        value = 0;
    } else {
        value = round((self.vedioModel.progress / 100.0) * 10000) / 10000;
    }
    self.videoView.timeSlider.value = value * _totalTime;
    [self updateTimeWithTimeNow:self.videoView.timeSlider.value andTotalTime:_totalTime];
    CMTime time = CMTimeMake(self.videoView.timeSlider.value, 1);
    __weak typeof(self) weakself = self;
    [self.playerItem seekToTime:time completionHandler:^(BOOL finished) {
        [weakself pause];
        [weakself.videoView showLoadingView:NO];
        self.videoView.centerPlayButton.hidden = NO;
    }];
}

#pragma mark 更新时间轴
- (void)updateTimeWithTimeNow:(CGFloat)timeNow andTotalTime:(CGFloat)totalTime {
    int time = round(timeNow);
    int time_total = round(totalTime);
    self.videoView.timeLabel.text = [NSString stringWithFormat:@"%@/%@",[VedioPlayerConfig convertTime:time],[VedioPlayerConfig convertTime:time_total]];
}

#pragma mark 更新vedioView对象的frame
- (void)setFrame:(CGRect)frame {
    [self.view setFrame:frame];
    [self.videoView setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    [self.videoView setNeedsLayout];
    [self.videoView layoutIfNeeded];
}

#pragma mark 初始化对象
- (VedioPlayerView *)videoView {
    if (!_videoView) {
        _videoView = [[VedioPlayerView alloc]init];
    }
    return _videoView;
}

- (NSString *)videoId {
    return self.vedioModel.videoId;
}

- (CGFloat)videoProgress {
    CMTime time = CMTimeMake(self.videoView.timeSlider.value, 1);
    CMTime totalTime = CMTimeMake(self.videoView.timeSlider.maximumValue, 1);
    CGFloat scale = round(((CGFloat)time.value / (CGFloat)totalTime.value) * 10000) / 10000;
    
    return scale * 100;
}

@end
