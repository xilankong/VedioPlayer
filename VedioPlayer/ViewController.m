//
//  ViewController.m
//  VedioPlayer
//
//  Created by yanghuang on 2017/4/24.
//  Copyright © 2017年 com.yang. All rights reserved.
//

#import "ViewController.h"
#import "MusicPlayerView.h"

@interface ViewController ()<VedioPlayerViewDelegate>
@property (nonatomic, strong) MusicPlayerView *playerView;
@property (nonatomic, strong) VedioPlayerView *vedioPlayerView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    VedioModel *model = [[VedioModel alloc]init];
    model.musicURL = @"http://jfz-gxq-public2.oss-cn-hangzhou.aliyuncs.com/m/kepu01.mp4";
    self.vedioPlayerView = [[VedioPlayerView alloc]init];
    self.vedioPlayerView.delegate = self;
    [self.vedioPlayerView setUp:model];
    [self.view addSubview:self.vedioPlayerView];
    
    
    
//    self.playerView = [[MusicPlayerView alloc]initWithFrame:CGRectMake(0, 50, 320, 40)];
//    self.playerView.delegate = self;
//    [self.playerView setUp:model];
//    [self.view addSubview:self.playerView];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)removeAction:(id)sender {
    [self.playerView removeFromSuperview];
}

//播放失败的代理方法
-(void)playerViewFailed:(VedioPlayerView *)player {
    NSLog(@"播放失败的代理方法");
}
//缓存中的代理方法
-(void)playerViewBuffering:(VedioPlayerView *)player {
    NSLog(@"缓存中的代理方法");
}
//播放完毕的代理方法
-(void)playerViewFinished:(VedioPlayerView *)player {
    NSLog(@"播放完毕的代理方法");
}

- (void)dealloc
{
    self.playerView = nil;
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    if (size.width == 568) {
        [UIView animateWithDuration:0.25 animations:^{
            self.vedioPlayerView.frame = CGRectMake(0, 0, 568, 320);
        }];
    } else if (size.width == 320) {
        [UIView animateWithDuration:0.25 animations:^{
            self.vedioPlayerView.frame = CGRectMake(0, 0, 320, 200);
        }];
    }

}
@end
