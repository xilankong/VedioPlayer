//
//  ViewController.m
//  VedioPlayer
//
//  Created by yanghuang on 2017/4/24.
//  Copyright © 2017年 com.yang. All rights reserved.
//

#import "ViewController.h"
#import "MusicPlayerView.h"
#import "VedioPlayerViewController.h"

@interface ViewController ()
@property (nonatomic, strong) MusicPlayerView *playerView;
@property (nonatomic, strong) VedioPlayerViewController  *videoController;
@property (nonatomic, assign) BOOL isFullscreenMode;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"导航条";
    VedioModel *model = [[VedioModel alloc]init];
    model.contentURL = [NSURL URLWithString: @"http://1252828818.vod2.myqcloud.com/9e6670b4vodtransgzp1252828818/5296b7c79031868223419539153/v.f20.mp4"];

    self.videoController = [[VedioPlayerViewController alloc] initWithFrame:CGRectMake(0, 64, SCREEN_WIDTH, SCREEN_WIDTH * (9.0/16.0))];
    __weak typeof(self) weakself = self;
    self.videoController.willChangeToSmallscreenMode = ^{
        weakself.isFullscreenMode = NO;
        [weakself setNeedsStatusBarAppearanceUpdate];
    };
    self.videoController.willChangeToFullscreenMode = ^{
        weakself.isFullscreenMode = YES;
        [weakself setNeedsStatusBarAppearanceUpdate];
    };
    
    [self.view addSubview:self.videoController.view];
    [self.videoController setUpWithModel:model];
    
    VedioModel *model2 = [[VedioModel alloc]init];
    model2.progress = 30;
    model2.contentURL = [NSURL URLWithString: @"http://sc1.111ttt.com/2016/5/12/09/205092038385.mp3"];
    self.playerView = [[MusicPlayerView alloc]initWithFrame:CGRectMake(0, 250, 320, 40)];
    [self.playerView setUpWithModel:model2];
    [self.view addSubview:self.playerView];
    
    
    [self.view bringSubviewToFront:self.videoController.view];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)removeAction:(id)sender {

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

-(BOOL)prefersStatusBarHidden {
    return _isFullscreenMode;
}

@end
