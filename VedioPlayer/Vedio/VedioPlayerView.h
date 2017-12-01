//
//  VedioPlayerView.h
//  VedioPlayer
//
//  Created by yanghuang on 2017/5/27.
//  Copyright © 2017年 com.yang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VedioPlayerConfig.h"
#import "ProgressSlider.h"
@class VedioPlayerView;

@interface VedioPlayerView : UIView

//控制层
@property (nonatomic, strong) UIView *controlView;

//工具条控件
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UIButton *landscapeButton;
@property (nonatomic, strong) ProgressSlider *timeSlider;

@property (nonatomic, strong) UIButton *centerPlayButton;
@property (nonatomic, strong) UIView *loadingView;

@property (nonatomic, strong) UIView *toolBarView;
@property (nonatomic, strong) UIImageView *thumbnailImageView;

@property (nonatomic, strong) AVPlayer *player;

- (void)showLoadingView:(BOOL)show;

@end

