//
//  SPImageFilterViewController.m
//  AudioVideo
//
//  Created by 王杰 on 2020/8/20.
//  Copyright © 2020 raintai. All rights reserved.
//

#import "SPImageFilterViewController.h"
#import "GPUImage.h"

@interface SPImageFilterViewController ()

@end

@implementation SPImageFilterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.title = @"为本地图片添加滤镜";
    
    UIImage *inputImg = [UIImage imageNamed:@"cyber"];
    

    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 100, self.view.frame.size.width, (720/1280.0)*self.view.frame.size.width)];
    imgView.image = [self addfilterGroup: inputImg];
    [self.view addSubview:imgView];
}

- (UIImage *)addSketchFilter:(UIImage *)oldImg {
    
     // 创建一个素描滤镜
     GPUImageSketchFilter *filter = [[GPUImageSketchFilter alloc] init];
        
     // 设置将要渲染的区域
     [filter forceProcessingAtSize:oldImg.size];
     [filter useNextFrameForImageCapture];
     // 获取数据源
     GPUImagePicture *stillImgSrc = [[GPUImagePicture alloc] initWithImage:oldImg];
     // 添加滤镜
     [stillImgSrc addTarget:filter];
     // 开始渲染
     [stillImgSrc processImage];
    
     UIImage *newImg = [filter imageFromCurrentFramebuffer];
    return newImg;
}

- (UIImage *)addfilterGroup:(UIImage *)oldImg {
    // 混合滤镜关键
    GPUImageFilterGroup *filterGroup = [[GPUImageFilterGroup alloc] init];
        
    // 添加 filter
    /**
     原理：
     1. filterGroup(addFilter) 滤镜组添加每个滤镜
     2. 按添加顺序（可自行调整）前一个filter(addTarget) 添加后一个filter
     3. filterGroup.initialFilters = @[第一个filter]];
     4. filterGroup.terminalFilter = 最后一个filter;
     */
    GPUImageColorInvertFilter *filter1 = [[GPUImageColorInvertFilter alloc] init];
        
    //伽马线滤镜
    GPUImageGammaFilter *filter2 = [[GPUImageGammaFilter alloc]init];
    filter2.gamma = 0.2;
    
    //曝光度滤镜
    GPUImageExposureFilter *filter3 = [[GPUImageExposureFilter alloc]init];
    filter3.exposure = -1.0;
    
    //怀旧
    GPUImageSepiaFilter *filter4 = [[GPUImageSepiaFilter alloc] init];
    
    // 所有的filter添加到filterGroup上
    [filterGroup addFilter:filter1];
    [filterGroup addFilter:filter2];
    [filterGroup addFilter:filter3];
    [filterGroup addFilter:filter4];
    
    // 注意下面的add ~ (感觉就是一个摞一个.)
    [filter1 addTarget:filter2];
    [filter2 addTarget:filter3];
    [filter3 addTarget:filter4];
    
    filterGroup.initialFilters = @[filter1];
    filterGroup.terminalFilter = filter4;
    
    [filterGroup forceProcessingAtSize:oldImg.size];
    [filterGroup useNextFrameForImageCapture];
    
     // 获取数据源
     GPUImagePicture *stillImgSrc = [[GPUImagePicture alloc] initWithImage:oldImg];
     // 添加滤镜
     [stillImgSrc addTarget:filterGroup];
     // 开始渲染
     [stillImgSrc processImage];
    
     UIImage *newImg = [filterGroup imageFromCurrentFramebuffer];
        return newImg;
}

@end
