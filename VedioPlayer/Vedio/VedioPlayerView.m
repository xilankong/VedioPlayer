//
//  VedioPlayerView.m
//  VedioPlayer
//
//  Created by yanghuang on 2017/5/27.
//  Copyright © 2017年 com.yang. All rights reserved.
//

#import "VedioPlayerView.h"
#import <Masonry/Masonry.h>
#import "AppDelegate.h"

@interface VedioPlayerView ()


@end

@implementation VedioPlayerView

#pragma mark 初始化组件\初始化playerListener

+(Class)layerClass {
    return [AVPlayerLayer class];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initUI];
    }
    return self;
}

- (void)initUI {
    //播放层放置在self.layer
    
    __weak typeof(self) weakself = self;
    
    self.player = [[AVPlayer alloc]init];
    self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [(AVPlayerLayer *)self.layer setPlayer:self.player];
    
    //缩略图
    self.thumbnailImageView = [[UIImageView alloc]init];
    [self addSubview:self.thumbnailImageView];
    [self.thumbnailImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(weakself);
    }];
    //控制层
    self.controlView = [[UIView alloc]init];
    [self addSubview:self.controlView];
    self.controlView.backgroundColor = [UIColor clearColor];
    [self.controlView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(weakself);
    }];
    
    [self initCenterControlView];
    [self initToolBar];
}

- (void)initCenterControlView {
    __weak typeof(self) weakself = self;
    
    self.centerPlayButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.centerPlayButton setImage:[UIImage imageNamed:@"icon-plau-big"] forState:UIControlStateNormal];
    [self.controlView addSubview:self.centerPlayButton];
    [self.centerPlayButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(weakself.controlView);
        make.width.height.mas_equalTo(50);
    }];
    
}

- (void)initToolBar {
    __weak typeof(self) weakself = self;
    self.toolBarView = [[UIView alloc]init];
    self.toolBarView.backgroundColor = [[UIColor blackColor]colorWithAlphaComponent:0.5];
    [self.controlView addSubview:self.toolBarView];
    
    [self.toolBarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.right.equalTo(weakself.controlView);
        make.height.equalTo(@(toolBarHeight));
    }];
    
    self.playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.playButton setImage:[UIImage imageNamed:@"video-play"] forState:UIControlStateNormal];
    
    [self.toolBarView addSubview:self.playButton];
    
    [self.playButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.bottom.equalTo(weakself.toolBarView);
        make.centerY.equalTo(weakself.toolBarView);
        make.width.mas_equalTo(35);
    }];
    
    self.timeSlider = [[ProgressSlider alloc] init];
    [self.toolBarView addSubview:self.timeSlider];
    
    self.timeLabel = [[UILabel alloc]init];
    self.timeLabel.textColor = [UIColor whiteColor];
    self.timeLabel.font = [UIFont systemFontOfSize:12];
    self.timeLabel.text = @"00:00:00/00:00:00";
    self.timeLabel.textAlignment = NSTextAlignmentRight;
    [self.toolBarView addSubview:self.timeLabel];
    
    self.landscapeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.landscapeButton setImage:[UIImage imageNamed:@"fullscreen"] forState:UIControlStateNormal];
    [self.toolBarView addSubview:self.landscapeButton];
    
    [self.timeSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(weakself.playButton.mas_trailing).offset(5);
        make.top.bottom.equalTo(weakself.toolBarView);
        make.trailing.equalTo(weakself.timeLabel.mas_leading).offset(-5);
    }];
    
    [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(weakself.landscapeButton.mas_leading).offset(-5);
        make.centerY.equalTo(weakself.toolBarView);
        make.height.mas_equalTo(15);
        make.width.mas_equalTo(110);
    }];
    
    [self.landscapeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.top.bottom.equalTo(weakself.toolBarView);
        make.centerY.equalTo(weakself.toolBarView);
        make.width.mas_equalTo(35);
    }];
}


@end

