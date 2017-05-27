//
//  MusicSlider.m
//  VedioPlayer
//
//  Created by yanghuang on 2017/5/27.
//  Copyright © 2017年 com.yang. All rights reserved.
//

#import "MusicSlider.h"
/* 拖动按钮的宽度 */
#define kBtnWith 14

/* 整个bar的宽度 */
#define kMyPlayProgressViewWidth (self.frame.size.width - (kBtnWith*0.5)*2)
/* slider 的高度 */
#define  kPlayProgressBarHeight 3


@implementation MusicSlider{
    
    UIView *_bgProgressView;         // 背景颜色
    UIView *_ableBufferProgressView; // 缓冲进度颜色
    UIView *_finishPlayProgressView; // 已经播放的进度颜色
    CGPoint _lastPoint;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        _minimumValue = 0.f;
        _maximumValue = 1.f;
        
        self.backgroundColor = [UIColor clearColor];
        
        CGFloat showY = (self.frame.size.height - kPlayProgressBarHeight)*0.5;
        
        /* 背景 */
        _bgProgressView = [[UIView alloc] initWithFrame:CGRectMake(kBtnWith*0.5, showY, kMyPlayProgressViewWidth, kPlayProgressBarHeight)];
        _bgProgressView.backgroundColor = [UIColor blackColor];
        [self addSubview:_bgProgressView];
        
        /* 缓存进度 */
        _ableBufferProgressView = [[UIView alloc] initWithFrame:CGRectMake(kBtnWith*0.5, showY, 0, kPlayProgressBarHeight)];
        _ableBufferProgressView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        [self addSubview:_ableBufferProgressView];
        
        /* 播放进度 */
        _finishPlayProgressView = [[UIView alloc] initWithFrame:CGRectMake(kBtnWith*0.5, showY, 0, kPlayProgressBarHeight)];
        _finishPlayProgressView.backgroundColor = [UIColor whiteColor];
        [self addSubview:_finishPlayProgressView];
        
        /* 滑动按钮 */
        _sliderBtn.backgroundColor = [UIColor whiteColor];
        _sliderBtn = [[MusicSliderBtn alloc] initWithFrame:CGRectMake(0, showY, 44, 44)];
        CGPoint center = _sliderBtn.center;
        center.x = _bgProgressView.frame.origin.x;
        center.y = _finishPlayProgressView.center.y;
        _sliderBtn.center = center;
        
        
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

- (void)setPlayProgressBackgoundColor:(UIColor *)playProgressBackgoundColor{
    if (_playProgressBackgoundColor != playProgressBackgoundColor) {
        _finishPlayProgressView.backgroundColor = playProgressBackgoundColor;
    }
}

- (void)setTrackBackgoundColor:(UIColor *)trackBackgoundColor{
    if (_trackBackgoundColor != trackBackgoundColor) {
        _ableBufferProgressView.backgroundColor = trackBackgoundColor;
    }
}

- (void)setProgressBackgoundColor:(UIColor *)progressBackgoundColor{
    if (_progressBackgoundColor != progressBackgoundColor) {
        _bgProgressView.backgroundColor = progressBackgoundColor;
    }
}

- (void)setPlayProgressBackgoundImage:(UIImage *)playProgressBackgoundImage {
    
    UIImageView *imageView = [[UIImageView alloc]initWithImage:playProgressBackgoundImage];
    imageView.frame = CGRectMake(0, 0, kMyPlayProgressViewWidth, kPlayProgressBarHeight);
    [_finishPlayProgressView addSubview:imageView];
    _finishPlayProgressView.layer.masksToBounds = YES;
}

- (void)setTrackBackgoundImage:(UIImage *)trackBackgoundImage {
    UIImageView *imageView = [[UIImageView alloc]initWithImage:trackBackgoundImage];
    imageView.frame = CGRectMake(0, 0, kMyPlayProgressViewWidth, kPlayProgressBarHeight);
    [_ableBufferProgressView addSubview:imageView];
    _ableBufferProgressView.layer.masksToBounds = YES;
}

- (void)setProgressBackgoundImage:(UIImage *)progressBackgoundImage {
    UIImageView *imageView = [[UIImageView alloc]initWithImage:progressBackgoundImage];
    imageView.frame = CGRectMake(0, 0, kMyPlayProgressViewWidth, kPlayProgressBarHeight);
    [_bgProgressView addSubview:imageView];
    _bgProgressView.layer.masksToBounds = YES;
}

/**
 进度值
 */
- (void)setValue:(CGFloat)value{
    
    _value = value;
    CGFloat progressValue = value / _maximumValue;
    if (progressValue>1) {
        progressValue = 1;
    }
    CGFloat finishValue = _bgProgressView.frame.size.width * progressValue;
    CGPoint tempPoint = _sliderBtn.center;
    tempPoint.x =  _bgProgressView.frame.origin.x + finishValue;
    
    if (tempPoint.x >= _bgProgressView.frame.origin.x &&
        tempPoint.x <= (self.frame.size.width - (kBtnWith*0.5))){
        
        _sliderBtn.center = tempPoint;
        _lastPoint = _sliderBtn.center;
        
        CGRect tempFrame = _finishPlayProgressView.frame;
        tempFrame.size.width = tempPoint.x;
        _finishPlayProgressView.frame = tempFrame;
    }
    
}

/**
 设置缓冲进度值
 */
-(void)setTrackValue:(CGFloat)trackValue{
    _trackValue = trackValue;
    CGFloat progressValue = _trackValue / _maximumValue;
    if (progressValue>1) {
        progressValue = 1;
    }
    CGFloat finishValue = _bgProgressView.frame.size.width * progressValue;
    
    CGRect tempFrame = _ableBufferProgressView.frame;
    tempFrame.size.width = finishValue;
    _ableBufferProgressView.frame = tempFrame;
}

/**
 拖动值发生改变
 */
- (void)dragMoving: (UIButton *)btn withEvent:(UIEvent *)event{
    
    CGPoint point = [[[event allTouches] anyObject] locationInView:self];
    CGFloat offsetX = point.x - _lastPoint.x;
    CGPoint tempPoint = CGPointMake(btn.center.x + offsetX, btn.center.y);
    
    // 得到进度值
    CGFloat progressValue = (tempPoint.x - _bgProgressView.frame.origin.x)*1.0f/_bgProgressView.frame.size.width;
    if (progressValue<0) {
        progressValue = 0;
    }
    if (progressValue > 1) {
        progressValue = 1;
    }
    [self setValue:progressValue*_maximumValue];
    [_delegate sliderScrubbing];
}
// 开始拖动
- (void)beiginSliderScrubbing{
    [_delegate beiginSliderScrubbing];
}
// 结束拖动
- (void)endSliderScrubbing{
    [_delegate endSliderScrubbing];
}
@end


/**
 *  为了让拖动按钮变得更大
 */
@implementation MusicSliderBtn{
    UIImageView *_iconImageView;
    UIActivityIndicatorView *_activity;
}

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
        _iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.frame.size.width - kBtnWith)*0.5,0.5*(self.frame.size.height - kBtnWith),kBtnWith, kBtnWith)];
        _iconImageView.backgroundColor = [UIColor whiteColor];
        _iconImageView.layer.cornerRadius = _iconImageView.frame.size.height*0.5;
        _iconImageView.layer.masksToBounds = YES;
        [self addSubview:_iconImageView];
        _activity = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        CGAffineTransform transform = CGAffineTransformMakeScale(.6f, .6f);
        _activity.center = CGPointMake(frame.size.height/2.0, frame.size.height/2.0);
        _activity.transform = transform;
        _activity.userInteractionEnabled  = NO;
        [self addSubview:_activity];
    }
    return self;
}

@end
