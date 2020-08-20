//
//  SPVideoFilterViewController.m
//  AudioVideo
//
//  Created by 王杰 on 2020/8/20.
//  Copyright © 2020 raintai. All rights reserved.
//

#import "SPVideoFilterViewController.h"
#import "GPUImage.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface SPVideoFilterViewController ()

@property (nonatomic,strong) GPUImageVideoCamera *videoCamera;
@property (nonatomic,strong) GPUImageOutput<GPUImageInput> * filter;
@property (nonatomic,strong) GPUImageMovieWriter * movieWriter;

@property (nonatomic,strong) NSURL * movieURL;

@end

@implementation SPVideoFilterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    // 设置摄像头
    _videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    
    _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    _videoCamera.horizontallyMirrorRearFacingCamera = NO;
    _videoCamera.horizontallyMirrorFrontFacingCamera = NO;
    
    // 意创建了一个滤镜
    _filter = [[GPUImageSepiaFilter alloc] init];
    
    [_videoCamera addTarget:_filter];
    
    // 显示
    GPUImageView * filterView = [[GPUImageView alloc] init];
    self.view = filterView;
    
    // 存储路径
    NSString * pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
    // - 如果文件已存在,AVAssetWriter不允许直接写进新的帧,所以会删掉老的视频文件
    unlink([pathToMovie UTF8String]);
    self.movieURL = [NSURL fileURLWithPath:pathToMovie];
    
    // 设置writer 后面的size可改 ~ 现在来说480*640有点太差劲了
    _movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:self.movieURL size:CGSizeMake(480.0, 640.0)];
    _movieWriter.encodingLiveVideo = YES;
    
    [_filter addTarget:_movieWriter];
    [_filter addTarget:filterView];
    
    // 开始
    [_videoCamera startCameraCapture];
    
     UIButton *button = [[UIButton alloc]initWithFrame:CGRectMake(30, 120, 100, 50)];
     button.backgroundColor = [UIColor cyanColor];
    [button setTitle:@"开始录制" forState:UIControlStateNormal];
    [button setTitle:@"停止录制" forState:UIControlStateSelected];
       
     [self.view addSubview:button];
    [button addTarget:self action:@selector(btnAction:) forControlEvents:UIControlEventTouchUpInside];

}

- (void)btnAction:(UIButton *)btn {
    if (btn.selected) {
        [self.filter removeTarget:self.movieWriter];
        self.videoCamera.audioEncodingTarget = nil;
        [self.movieWriter finishRecording];
        NSLog(@"Movie completed");
        // 写入相册
        [self writeToPhotoAlbum];
    }else {
        self.videoCamera.audioEncodingTarget = self.movieWriter;
        [self.movieWriter startRecording];
    }
    btn.selected = !btn.selected;
}

/////////////////////////////////////////////////////////////////////

- (void)writeToPhotoAlbum {
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:self.movieURL]) {
        [library writeVideoAtPathToSavedPhotosAlbum:self.movieURL completionBlock:^(NSURL *assetURL, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误"
                                                                    message:@"保存失败"
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                    [alert show];

                } else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示"
                                                                    message:@"保存到相册成功"
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                    [alert show];
                }
            });
        }];
    }
}

@end
