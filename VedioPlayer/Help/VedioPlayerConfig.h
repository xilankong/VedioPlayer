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


#define playProgressColor [UIColor whiteColor]
#define bufferProgressColor [[UIColor whiteColor]colorWithAlphaComponent:0.5]
#define sliderBackgoundColor [[UIColor whiteColor]colorWithAlphaComponent:0.2]
#define toolBarHeight 50.0f
#define SCREEN_HEIGHT  [UIScreen mainScreen].bounds.size.height
#define SCREEN_WIDTH   [UIScreen mainScreen].bounds.size.width


#pragma mark 常用枚举

typedef NS_ENUM(NSUInteger, VedioStatus) {
    VedioStatusPause,       // 暂停播放
    VedioStatusPlaying,       // 播放中
    VedioStatusBuffering,     // 缓冲中
    VedioStatusFinished,       //停止播放
    VedioStatusFailed        // 播放失败
};

@interface VedioPlayerConfig : NSObject

+ (NSString *)convertTime:(CGFloat)second;
+ (UIImage *)getThumbnailImage:(NSURL *)videoURL;

@end
