//
//  JFZPlayerConfig.h
//  VedioPlayer
//
//  Created by yanghuang on 2017/5/27.
//  Copyright © 2017年 com.yang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class VedioMusicPlayerView;

#define TrackColor [UIColor colorWithRed:128/255.0 green:128/255.0 blue:128/255.0 alpha:1.0]
#define SCREEN_HEIGHT  [UIScreen mainScreen].bounds.size.height
#define SCREEN_WIDTH   [UIScreen mainScreen].bounds.size.width

#pragma mark 常用枚举

typedef NS_ENUM(NSUInteger, VedioStatus) {
    VedioStatusFailed,        // 播放失败
    VedioStatusBuffering,     // 缓冲中
    VedioStatusPlaying,       // 播放中
    VedioStatusFinished,       //停止播放
    VedioStatusPause       // 暂停播放
};

@interface VedioPlayerConfig : NSObject

+ (NSString *)convertTime:(CGFloat)second;

@end
