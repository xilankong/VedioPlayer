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
-(void)playerViewFailed:(VedioPlayerView *)player;
//缓存中的代理方法
-(void)playerViewBuffering:(VedioPlayerView *)player;
//播放完毕的代理方法
-(void)playerViewFinished:(VedioPlayerView *)player;

@end

@interface VedioPlayerView : UIView

@property (nonatomic, weak) id<VedioPlayerViewDelegate> delegate;

@end
