//
//  VedioPlayerViewController.h
//  VedioPlayer
//
//  Created by yanghuang on 2017/11/22.
//  Copyright © 2017年 com.yang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VedioModel.h"

@interface VedioPlayerViewController : UIViewController

/** videoPlayerView 消失 */
@property (nonatomic, copy)void(^dimissCompleteBlock)(void);
/** 进入最小化状态 */
@property (nonatomic, copy)void(^willChangeToSmallscreenMode)(void);
/** 进入全屏状态 */
@property (nonatomic, copy)void(^willChangeToFullscreenMode)(void);

@property (nonatomic, assign) CGRect frame;

- (instancetype)initWithFrame:(CGRect)frame;

- (void)startWithModel:(VedioModel *)model;

- (void)stop;

- (void)changeModel:(VedioModel *)vedioModel;
@end
