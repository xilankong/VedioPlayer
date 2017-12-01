//
//  MusicPlayerView.h
//  VedioPlayer
//
//  Created by yanghuang on 2017/5/27.
//  Copyright © 2017年 com.yang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VedioPlayerView.h"
#import "VedioModel.h"
#import "ProgressSlider.h"

@interface MusicPlayerView : UIView

/**
 初始化模型

 @param model 数据模型
 */
- (void)setUpWithModel:(VedioModel *)model;

/**
 换歌
 @param musicModel 数据模型
 */
- (void)changeMusicWithModel:(VedioModel *)musicModel;

@end
