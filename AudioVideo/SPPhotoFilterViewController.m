//
//  SPPhotoViewController.m
//  AudioVideo
//
//  Created by 王杰 on 2020/8/20.
//  Copyright © 2020 raintai. All rights reserved.
//

#import "SPPhotoFilterViewController.h"
#import "GPUImage.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface SPPhotoFilterViewController ()
@property (nonatomic,strong) GPUImageStillCamera *camera;
@property (nonatomic,strong) GPUImageOutput<GPUImageInput> * filter;
@property (nonatomic, strong) GPUImageView *imageView;//?< 展示camera的view
@end

@implementation SPPhotoFilterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"为相机添加滤镜";
   self.camera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];
    self.camera.outputImageOrientation = UIInterfaceOrientationPortrait;
    self.camera.horizontallyMirrorFrontFacingCamera = YES;
    
    //滤镜 创建， 这个滤镜是黑白的效果 还有很多 自己去看
    self.filter = [[GPUImageSketchFilter alloc] init];
    
    //创建展示相机的视图
    self.imageView = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    self.imageView.center = self.view.center;
    [self.view addSubview:self.imageView];
    
    //这里一定要注意 一定要先加滤镜->在加视图->然后吧camera开始获取视频图像
    [self.camera addTarget:self.filter];
    [self.filter addTarget:self.imageView];
    
    //开始获取视频
    [self.camera startCameraCapture];

    //按钮拍照
    UIButton *button = [[UIButton alloc]initWithFrame:CGRectMake((self.view.bounds.size.width-80)*0.5, self.view.bounds.size.height-120, 100, 50)];
    button.backgroundColor = [UIColor cyanColor];
    [button setTitle:@"点击拍照" forState:UIControlStateNormal];
    
    [self.view addSubview:button];
    [button addTarget:self action:@selector(takePhotoToAlbum) forControlEvents:UIControlEventTouchUpInside];
}

- (void)takePhotoToAlbum
{
    [self.camera capturePhotoAsJPEGProcessedUpToFilter:self.filter withCompletionHandler:^(NSData *processedJPEG, NSError *error) {
        
//        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
//
//        [library writeImageDataToSavedPhotosAlbum:processedJPEG metadata:_camera.currentCaptureMetadata completionBlock:^(NSURL *assetURL, NSError *error2)
//         {
//             if (error2) {
//                 NSLog(@"ERROR: the image failed to be written");
//             }
//             else {
//                 NSLog(@"PHOTO SAVED - assetURL: %@", assetURL);
//             }
//
//         }];
        
        
        UIImage * chooseImage = [UIImage imageWithData:processedJPEG];
        if (chooseImage) {
            UIImageWriteToSavedPhotosAlbum(chooseImage, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
        }
    }];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (!error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示"
                                                        message:@"保存到相册成功"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}


@end
