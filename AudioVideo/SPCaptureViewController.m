//
//  CaptureViewController.m
//  AudioVideo
//
//  Created by 王杰 on 2020/8/19.
//  Copyright © 2020 raintai. All rights reserved.
//

#import "SPCaptureViewController.h"
#import "SPCaptureView.h"

@interface SPCaptureViewController ()
@property (nonatomic, strong) SPCaptureView *captureView;
@end

@implementation SPCaptureViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    
    self.captureView = [[SPCaptureView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.captureView];
    [self.captureView showPreview];
    
    UIButton *startBtn = [[UIButton alloc] initWithFrame:CGRectMake(20, 70, 60, 60)];
    startBtn.backgroundColor = [UIColor greenColor];
    [startBtn setTitle:@"开始" forState:UIControlStateNormal];
    [startBtn addTarget:self action:@selector(startBtnAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:startBtn];
    
    UIButton *stopBtn = [[UIButton alloc] initWithFrame:CGRectMake(20, 150, 60, 60)];
    stopBtn.backgroundColor = [UIColor redColor];
    [stopBtn setTitle:@"停止" forState:UIControlStateNormal];
    [stopBtn addTarget:self action:@selector(stopBtnAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:stopBtn];
}

- (void)startBtnAction {
    [self.captureView startRecord];
}

- (void)stopBtnAction {
    [self.captureView stopRecord];
}

@end
