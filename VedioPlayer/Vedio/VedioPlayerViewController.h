//
//  VedioPlayerViewController.h
//  VedioPlayer
//
//  Created by yanghuang on 2017/11/22.
//  Copyright © 2017年 com.yang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VedioModel.h"
#import "VedioPlayerView.h"
@interface VedioPlayerViewController : UIViewController

/** videoPlayerView 消失 */
@property (nonatomic, copy)void(^dimissCompleteBlock)(void);
/** 将要进入最小化状态 */
@property (nonatomic, copy)void(^willChangeToSmallscreenMode)(void);
/** 将要全屏状态 */
@property (nonatomic, copy)void(^willChangeToFullscreenMode)(void);
/** 进入最小化状态 */
@property (nonatomic, copy)void(^didChangeToSmallscreenMode)(void);
/** 进入全屏状态 */
@property (nonatomic, copy)void(^didChangeToFullscreenMode)(void);
/** 进入后台状态 */
@property (nonatomic, copy)void(^willGoToBackground)(void);
/** 播放完成 */
@property (nonatomic, copy)void(^playerFinished)(void);

@property (nonatomic, copy) NSString *videoId;

@property (nonatomic, assign) CGFloat videoProgress;

@property (nonatomic, assign) CGRect frame;

- (instancetype)initWithFrame:(CGRect)frame;

- (void)setUpWithModel:(VedioModel *)model;

- (void)changeModel:(VedioModel *)vedioModel;

@end
