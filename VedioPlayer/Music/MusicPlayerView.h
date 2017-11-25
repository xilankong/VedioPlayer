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

- (void)setUpWithModel:(VedioModel *)model;

- (void)changeMusicWithModel:(VedioModel *)musicModel;

@end
