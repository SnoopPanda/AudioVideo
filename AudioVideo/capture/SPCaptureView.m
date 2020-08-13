//
//  SPCaptureView.m
//  AudioVideo
//
//  Created by 王杰 on 2020/8/12.
//  Copyright © 2020 raintai. All rights reserved.
//

#import "SPCaptureView.h"
#import <AVFoundation/AVFoundation.h>
#import "SPVideoEncoder.h"
#import "SPAudioEncoder.h"

@interface SPCaptureView ()<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic, strong) dispatch_queue_t           captureQueue;

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic, strong) AVCaptureSession           *videoSession;

@property (nonatomic, strong) AVCaptureDeviceInput       *frontCameraInput;
@property (nonatomic, strong) AVCaptureDeviceInput       *backCameraInput;
@property (nonatomic, strong) AVCaptureDeviceInput       *audioMicInput;

@property (nonatomic, strong) AVCaptureConnection        *audioConnection;
@property (nonatomic, strong) AVCaptureConnection        *videoConnection;

@property (nonatomic, strong) AVCaptureVideoDataOutput   *videoOutput;
@property (nonatomic, strong) AVCaptureAudioDataOutput   *audioOutput;

@property (nonatomic, assign) BOOL curCameraIsFront;

@property (nonatomic, strong) SPVideoEncoder *videoEncoder;
@property (nonatomic, strong) SPAudioEncoder *audioEncoder;

@end

@implementation SPCaptureView

- (NSString *)h264FilePath {
    NSString* h264FilePath = [[self getFilePathDir] stringByAppendingPathComponent:@"test.h264"];
    return h264FilePath;
}

- (NSString *)aacFilePath {
    NSString* aacFilePath = [[self getFilePathDir] stringByAppendingPathComponent:@"test.aac"];
    return aacFilePath;
}

- (NSString *)getFilePathDir{
    NSString *fileDir = [NSString stringWithFormat:@"%@/Documents/encoder", NSHomeDirectory()];

    BOOL isDir = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL existed = [fileManager fileExistsAtPath:fileDir isDirectory:&isDir];
    if ( !(isDir == YES && existed == YES) )
    {
        [fileManager createDirectoryAtPath:fileDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return fileDir;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.curCameraIsFront = YES;
        self.videoEncoder = [[SPVideoEncoder alloc] initWithFilePath:[self h264FilePath]];
        self.audioEncoder = [[SPAudioEncoder alloc] initWithExpectType:SPAudioTypeAAC filePath:[self aacFilePath]];
    }
    return self;
}

- (void)startRunning {
    self.previewLayer.frame = self.bounds;
    [self.layer insertSublayer:self.previewLayer atIndex:0];
    
    if (self.videoSession) {
        [self.videoSession startRunning];
    }
}

#pragma mark - Public

- (void)stopRunning {
    [self.videoSession stopRunning];
}

- (void)flipCamera {
    
    [self.videoSession startRunning];
    [self.videoSession beginConfiguration];
    
    if (self.curCameraIsFront) {
           [self.videoSession removeInput:self.frontCameraInput];
           if ([self.videoSession canAddInput:self.backCameraInput]) {
               [self.videoSession addInput:self.backCameraInput];
           }
           self.videoConnection.videoMirrored = NO;
       }else {
           [self.videoSession removeInput:self.backCameraInput];
           if ([self.videoSession canAddInput:self.frontCameraInput]) {
               [self.videoSession addInput:self.frontCameraInput];
           }
           self.videoConnection.videoMirrored = YES;
       }
       
       self.videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
       
       self.curCameraIsFront = !self.curCameraIsFront;
       
       [self.videoSession commitConfiguration];
       [self.videoSession startRunning];
}

#pragma mark - Delegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    [self encodeFrame:sampleBuffer isVideo:captureOutput == self.videoOutput];
}

- (void)encodeFrame:(CMSampleBufferRef)sampleBuffer isVideo:(BOOL)isVideo {

    if (CMSampleBufferDataIsReady(sampleBuffer)) {
        if (isVideo) {
            [self.videoEncoder encodeSampleBuffer:sampleBuffer];
        }else {
            [self.audioEncoder encodeSampleBuffer:sampleBuffer];
        }
    }
}

#pragma mark - Private

- (AVCaptureDevice *)frontCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}

- (AVCaptureDevice *)backCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition) position {
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

#pragma mark - Lazy load

- (dispatch_queue_t)captureQueue {
    if (_captureQueue == nil) {
        _captureQueue = dispatch_queue_create("av.capture", DISPATCH_QUEUE_SERIAL);
    }
    return _captureQueue;
}

- (AVCaptureVideoPreviewLayer *)previewLayer {
    if (_previewLayer == nil) {
        AVCaptureVideoPreviewLayer *preview = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.videoSession];
        preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
        _previewLayer = preview;
    }
    return _previewLayer;
}

- (AVCaptureSession *)videoSession {
    if (_videoSession == nil) {
        _videoSession = [[AVCaptureSession alloc] init];
        _videoSession.sessionPreset = AVCaptureSessionPreset640x480;
        
        if ([_videoSession canAddInput:self.frontCameraInput]) {
            [_videoSession addInput:self.frontCameraInput];
        }
        
        if ([_videoSession canAddInput:self.audioMicInput]) {
            [_videoSession addInput:self.audioMicInput];
        }
        
        if ([_videoSession canAddOutput:self.videoOutput]) {
            [_videoSession addOutput:self.videoOutput];
        }

        if ([_videoSession canAddOutput:self.audioOutput]) {
            [_videoSession addOutput:self.audioOutput];
        }
        
        self.videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    }
    return _videoSession;
}

- (AVCaptureDeviceInput *)frontCameraInput {
    if (_frontCameraInput == nil) {
        NSError *error;
        _frontCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self frontCamera] error:&error];
        if (error) {
            NSLog(@"获取前置摄像头失败~");
        }
    }
    return _frontCameraInput;
}

- (AVCaptureDeviceInput *)backCameraInput {
    if (_backCameraInput == nil) {
        NSError *error;
        _backCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self backCamera] error:&error];
        if (error) {
            NSLog(@"获取后置摄像头失败~");
        }
    }
    return _backCameraInput;
}

- (AVCaptureDeviceInput *)audioMicInput {
    if (_audioMicInput == nil) {
        AVCaptureDevice *mic = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        NSError *error;
        _audioMicInput = [AVCaptureDeviceInput deviceInputWithDevice:mic error:&error];
        if (error) {
            NSLog(@"获取麦克风失败~");
        }
    }
    return _audioMicInput;
}

- (AVCaptureVideoDataOutput *)videoOutput {
    if (_videoOutput == nil) {
        _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
        [_videoOutput setSampleBufferDelegate:self queue:self.captureQueue];
        NSDictionary* setcapSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange], kCVPixelBufferPixelFormatTypeKey,
                                        nil];
        _videoOutput.videoSettings = setcapSettings;
    }
    return _videoOutput;
}

- (AVCaptureAudioDataOutput *)audioOutput {
    if (_audioOutput == nil) {
        _audioOutput = [[AVCaptureAudioDataOutput alloc] init];
        [_audioOutput setSampleBufferDelegate:self queue:self.captureQueue];
    }
    return _audioOutput;
}

- (AVCaptureConnection *)videoConnection {
    _videoConnection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
    _videoConnection.videoMirrored = YES;
    return _videoConnection;
}

- (AVCaptureConnection *)audioConnection {
    if (_audioConnection == nil) {
        _audioConnection = [self.audioOutput connectionWithMediaType:AVMediaTypeAudio];
    }
    return _audioConnection;
}

@end
