//
//  VedioPlayerView.h
//  VedioPlayer
//
//  Created by yanghuang on 2017/5/27.
//  Copyright © 2017年 com.yang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VedioPlayerConfig.h"

@class VedioPlayerView;

@protocol VedioPlayerViewDelegate <NSObject>

@optional
//播放失败的代理方法
-(void)jfzPlayerViewFailed:(VedioPlayerView *)player;
//缓存中的代理方法
-(void)jfzPlayerViewBuffering:(VedioPlayerView *)player;
//播放完毕的代理方法
-(void)jfzPlayerViewFinished:(VedioPlayerView *)player;

@end

@interface VedioPlayerView : UIView <VedioPlayerViewDelegate>

@property (nonatomic, weak) id<VedioPlayerViewDelegate> delegate;

@end
