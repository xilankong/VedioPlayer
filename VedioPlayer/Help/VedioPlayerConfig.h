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


#define SCREEN_HEIGHT  [UIScreen mainScreen].bounds.size.height
#define SCREEN_WIDTH   [UIScreen mainScreen].bounds.size.width

#define default_playProgressColor [UIColor whiteColor]
#define default_bufferProgressColor [[UIColor whiteColor]colorWithAlphaComponent:0.5]
#define default_sliderBackgoundColor [[UIColor whiteColor]colorWithAlphaComponent:0.2]
#define toolBarHeight 44.0f

#define playImage [UIImage imageNamed:@"video-play"]
#define pauseImage @"video-play"
#define playBigImage @"video-play"
#define fullScreenImage @"video-play"
#define backImage @"video-play"
#define settingImage @"video-play"

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
