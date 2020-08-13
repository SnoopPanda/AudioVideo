//
//  ViewController.m
//  AudioVideo
//
//  Created by 王杰 on 2020/8/12.
//  Copyright © 2020 raintai. All rights reserved.
//

#import "ViewController.h"
#import "SPCaptureView.h"

@interface ViewController ()
@property (nonatomic, strong) SPCaptureView *captureView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.captureView = [[SPCaptureView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.captureView];
    [self.captureView startRunning];
    
    UIButton *flipBtn = [[UIButton alloc] initWithFrame:CGRectMake(20, 70, 60, 60)];
    flipBtn.backgroundColor = [UIColor cyanColor];
    [flipBtn setTitle:@"翻转" forState:UIControlStateNormal];
    [flipBtn addTarget:self action:@selector(flipAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:flipBtn];
}

- (void)flipAction {
    [self.captureView flipCamera];
}


@end
