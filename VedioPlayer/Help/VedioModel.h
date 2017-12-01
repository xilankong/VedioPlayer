//
//  VedioModel.h
//  VedioPlayer
//
//  Created by yanghuang on 2017/5/27.
//  Copyright © 2017年 com.yang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface VedioModel : NSObject

@property (nonatomic, assign) CGFloat progress; // 0-100
@property (nonatomic, assign) CGFloat duration;

@property (nonatomic, strong) NSURL *contentURL;
@property (nonatomic, copy) NSString *videoId;
@property (nonatomic, copy) NSString *videoTitle;
@property (nonatomic, copy) NSString *imageUrl;
@end

