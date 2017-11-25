//
//  MusicSlider.h
//  VedioPlayer
//
//  Created by yanghuang on 2017/5/27.
//  Copyright © 2017年 com.yang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "VedioPlayerConfig.h"

@class ProgressSliderBtn;
@protocol ProgressSliderDelegate <NSObject>
// 开始拖动
- (void)beiginSliderScrubbing;
// 结束拖动
- (void)endSliderScrubbing;
// 拖动值发生改变
- (void)sliderScrubbing;

@end

@interface ProgressSlider : UIView

@property (nonatomic, weak) id<ProgressSliderDelegate> delegate;

@property (nonatomic, assign) CGFloat minimumValue;
@property (nonatomic, assign) CGFloat maximumValue;

@property (nonatomic, assign) CGFloat value;
@property (nonatomic, assign) CGFloat trackValue;
@property (nonatomic, assign) BOOL smallActivityView;

@property (nonatomic, strong) ProgressSliderBtn *sliderBtn;
@end

@interface ProgressSliderBtn : UIButton

- (void)showActivity:(BOOL)show;

@end

