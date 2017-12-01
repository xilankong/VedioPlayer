//
//  MusicSlider.m
//  VedioPlayer
//
//  Created by yanghuang on 2017/5/27.
//  Copyright © 2017年 com.yang. All rights reserved.
//

#import "ProgressSlider.h"
#import <Masonry/Masonry.h>
/* 拖动按钮的宽度 */
#define btnWith 10

/* 整个bar的宽度 */
#define playProgressViewWidth (self.frame.size.width - (btnWith * 0.5) * 2)
/* slider 的高度 */
#define  playProgressBarHeight 2

@interface ProgressSliderBtn : UIButton

@property(nonatomic, strong) UIImageView *iconImageView;
@property(nonatomic, strong) UIActivityIndicatorView *activity;

- (void)showActivity:(BOOL)show;

@end

@implementation ProgressSliderBtn

- (void)showActivity:(BOOL)show {
    if (show) {
        _activity.hidden = NO;
        [_activity startAnimating];
    } else {
        _activity.hidden = YES;
        [_activity stopAnimating];
    }
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        __weak typeof(self) weakself = self;
        _iconImageView = [[UIImageView alloc] init];
        [self addSubview:_iconImageView];
        [_iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(weakself);
            make.width.height.mas_equalTo(btnWith);
        }];
        
        _iconImageView.backgroundColor = [UIColor whiteColor];
        _iconImageView.layer.cornerRadius = btnWith * 0.5;
        _iconImageView.layer.masksToBounds = YES;
        
        _activity = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        CGAffineTransform transform = CGAffineTransformMakeScale(.4f, .4f);
        _activity.transform = transform;
        _activity.userInteractionEnabled  = NO;
        [self addSubview:_activity];
        [_activity mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(_iconImageView);
        }];
    }
    return self;
}

@end

@interface ProgressSlider()

@property (nonatomic, assign) CGPoint lastPoint;
@property (nonatomic, assign) CGFloat oldWidth;
@property (nonatomic, strong) UIView *sliderBackgroundView;         // 背景颜色
@property (nonatomic, strong) UIView *bufferProgressView; // 缓冲进度颜色
@property (nonatomic, strong) UIView *playProgressView; // 已经播放的进度颜色

@property (nonatomic, strong) ProgressSliderBtn *sliderBtn;

@end

@implementation ProgressSlider

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        _minimumValue = 0.f;
        _maximumValue = 1.f;
        
        self.backgroundColor = [UIColor clearColor];
        
        /* 背景 */
        _sliderBackgroundView = [[UIView alloc] init];
        _sliderBackgroundView.backgroundColor = default_sliderBackgoundColor;
        [self addSubview:_sliderBackgroundView];
        
        /* 缓存进度 */
        _bufferProgressView = [[UIView alloc] init];
        _bufferProgressView.backgroundColor = default_bufferProgressColor;
        [self addSubview:_bufferProgressView];
        
        /* 播放进度 */
        _playProgressView = [[UIView alloc] init];
        _playProgressView.backgroundColor = default_playProgressColor;
        [self addSubview:_playProgressView];
        
        /* 滑动按钮 */
        _sliderBtn.backgroundColor = [UIColor whiteColor];
        _sliderBtn = [[ProgressSliderBtn alloc] init];
        
        
        [_sliderBtn addTarget:self action:@selector(beiginSliderScrubbing) forControlEvents:UIControlEventTouchDown];
        //        [_sliderBtn addTarget:self action:@selector(endSliderScrubbing) forControlEvents:UIControlEventTouchCancel];
        [_sliderBtn addTarget:self action:@selector(dragMoving:withEvent:) forControlEvents:UIControlEventTouchDragInside];
        [_sliderBtn addTarget:self action:@selector(endSliderScrubbing) forControlEvents:UIControlEventTouchUpInside];
        [_sliderBtn addTarget:self action:@selector(endSliderScrubbing) forControlEvents:UIControlEventTouchUpOutside];
        _lastPoint = _sliderBtn.center;
        [self addSubview:_sliderBtn];
        
    }
    return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    if (playProgressViewWidth != _oldWidth) {
        CGFloat showY = (self.frame.size.height - playProgressBarHeight) * 0.5;
        CGFloat scale = playProgressViewWidth / _oldWidth;
        /* 背景 */
        _sliderBackgroundView.frame = CGRectMake(btnWith*0.5, showY, playProgressViewWidth, playProgressBarHeight);
        
        if (self.bufferValue > 0) {
            _bufferProgressView.frame = CGRectMake(btnWith*0.5, showY, _bufferProgressView.frame.size.width * scale , playProgressBarHeight);
        } else {
            /* 缓存进度 */
            _bufferProgressView.frame = CGRectMake(btnWith*0.5, showY, 0, playProgressBarHeight);
        }
        if (self.value > 0) {
            /* 播放进度 */
            _playProgressView.frame = CGRectMake(btnWith*0.5, showY, _playProgressView.frame.size.width * scale, playProgressBarHeight);
            _sliderBtn.center = CGPointMake(btnWith*0.5 + _playProgressView.frame.size.width, _sliderBtn.center.y);
        } else {
            /* 播放进度 */
            _playProgressView.frame = CGRectMake(btnWith*0.5, showY, 0, playProgressBarHeight);
            /* 滑动按钮 */
            _sliderBtn.frame = CGRectMake(0, showY, 30, self.frame.size.height);
            CGPoint center = _sliderBtn.center;
            center.x = _sliderBackgroundView.frame.origin.x;
            center.y = _playProgressView.center.y;
            _sliderBtn.center = center;
        }
        
        _oldWidth = playProgressViewWidth;
    }
}

#pragma mark 进度
- (void)setValue:(CGFloat)value{
    _value = value;
    CGFloat progressValue = value / _maximumValue;
    if (progressValue>1) {
        progressValue = 1;
    }
    CGFloat finishValue = _sliderBackgroundView.frame.size.width * progressValue;
    CGPoint tempPoint = _sliderBtn.center;
    tempPoint.x =  _sliderBackgroundView.frame.origin.x + finishValue;
    
    if (tempPoint.x >= _sliderBackgroundView.frame.origin.x &&
        tempPoint.x <= (self.frame.size.width - (btnWith*0.5))){
        
        _sliderBtn.center = tempPoint;
        _lastPoint = _sliderBtn.center;
        
        CGRect tempFrame = _playProgressView.frame;
        tempFrame.size.width = tempPoint.x - (btnWith*0.5);
        _playProgressView.frame = tempFrame;
    }
}

#pragma mark 缓冲进度
-(void)setBufferValue:(CGFloat)bufferValue{
    _bufferValue = bufferValue;
    CGFloat progressValue = _bufferValue / _maximumValue;
    if (progressValue>1) {
        progressValue = 1;
    }
    CGFloat finishValue = _sliderBackgroundView.frame.size.width * progressValue;
    
    CGRect tempFrame = _bufferProgressView.frame;
    tempFrame.size.width = finishValue;
    _bufferProgressView.frame = tempFrame;
}

#pragma mark 拖动值发生改变
- (void)dragMoving: (UIButton *)btn withEvent:(UIEvent *)event{
    if (self.disabled) {
        return;
    }
    CGPoint point = [[[event allTouches] anyObject] locationInView:self];
    CGFloat offsetX = point.x - _lastPoint.x;
    CGPoint tempPoint = CGPointMake(btn.center.x + offsetX, btn.center.y);
    
    // 得到进度值
    CGFloat progressValue = (tempPoint.x - _sliderBackgroundView.frame.origin.x)*1.0f/_sliderBackgroundView.frame.size.width;
    if (progressValue<0) {
        progressValue = 0;
    }
    if (progressValue > 1) {
        progressValue = 1;
    }
    [self setValue:progressValue*_maximumValue];
    if (self.delegate) {
        [_delegate sliderScrubbing];
    }
}
#pragma mark 开始拖动
- (void)beiginSliderScrubbing {
    if (self.disabled) {
        return;
    }
    if (self.delegate) {
        [_delegate beiginSliderScrubbing];
    }
}

#pragma mark 结束拖动
- (void)endSliderScrubbing {
    if (self.disabled) {
        return;
    }
    if (self.delegate) {
        [_delegate endSliderScrubbing];
    }
}

#pragma mark 显示loading
-(void)showActivity:(BOOL)show {
    [self.sliderBtn showActivity:show];
}

- (void)setPlayProgressColor:(UIColor *)playProgressColor {
    _playProgressColor = playProgressColor;
    _playProgressView.backgroundColor = _playProgressColor;
}

- (void)setBufferProgressColor:(UIColor *)bufferProgressColor {
    _bufferProgressColor = bufferProgressColor;
    _bufferProgressView.backgroundColor = _bufferProgressColor;
}

-(void)setSliderBackgoundColor:(UIColor *)sliderBackgoundColor {
    _sliderBackgoundColor = sliderBackgoundColor;
    _sliderBackgroundView.backgroundColor = _sliderBackgoundColor;
}

-(void)setSliderDotDiameter:(CGFloat)sliderDotDiameter {
    _sliderDotDiameter = sliderDotDiameter;
    [self.sliderBtn.iconImageView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(sliderDotDiameter);
    }];
    self.sliderBtn.iconImageView.layer.cornerRadius = sliderDotDiameter / 2.0;
    CGFloat scale = sliderDotDiameter / btnWith;
    CGAffineTransform transform = CGAffineTransformMakeScale(.4 * scale, .4 * scale);
    self.sliderBtn.activity.transform = transform;
}
@end
