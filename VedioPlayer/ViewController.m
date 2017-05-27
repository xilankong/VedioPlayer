//
//  ViewController.m
//  VedioPlayer
//
//  Created by yanghuang on 2017/4/24.
//  Copyright © 2017年 com.yang. All rights reserved.
//

#import "ViewController.h"
#import "MusicPlayerView.h"

@interface ViewController ()
@property (nonatomic, strong) MusicPlayerView *playerView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    VedioModel *model = [[VedioModel alloc]init];
    model.musicURL = @"http://jfz-gxq-public2.oss-cn-hangzhou.aliyuncs.com/m/kepu01.mp4";
    self.playerView = [[MusicPlayerView alloc]initWithFrame:CGRectMake(0, 50, 320, 40)];
    [self.playerView setUp:model];
    [self.view addSubview:self.playerView];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
