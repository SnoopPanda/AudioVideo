//
//  SPVideoEncoder.m
//  AudioVideo
//
//  Created by 王杰 on 2020/8/13.
//  Copyright © 2020 raintai. All rights reserved.
//

#import "SPVideoEncoder.h"
#import "SPFileWriter.h"

@interface SPVideoEncoder ()
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) SPFileWriter *fileWriter;

@property (nonatomic, assign) VTCompressionSessionRef compressionSession;
@property (nonatomic, assign) NSInteger frameID;

@end

@implementation SPVideoEncoder

- (void)dealloc {
    VTCompressionSessionCompleteFrames(self.compressionSession, kCMTimeInvalid);
    VTCompressionSessionInvalidate(self.compressionSession);
    CFRelease(self.compressionSession);
    self.compressionSession = NULL;
}

- (instancetype)initWithFilePath:(NSString *)filePath {
    if (self = [super init]) {
        self.filePath = filePath;
        self.fileWriter = [[SPFileWriter alloc] init];
        
        [self setupVideoSession];
    }
    return self;
}

- (void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    
    if (!self.compressionSession) {
        [self setupVideoSession];
        return;
    }
    //  1.保存 block 块
//    self.h264DataBlock = h264DataBlock;
    
    //  2.将sampleBuffer转成imageBuffer
    CVImageBufferRef imageBuffer = (CVImageBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    
    //  3.根据当前的帧数,创建CMTime的时间
    CMTime presentationTimeStamp = CMTimeMake(self.frameID++, 1000);
    VTEncodeInfoFlags flags;
    
    //  4.开始编码该帧数据
    OSStatus statusCode = VTCompressionSessionEncodeFrame(
                                                          self.compressionSession,
                                                          imageBuffer,
                                                          presentationTimeStamp,
                                                          kCMTimeInvalid,
                                                          NULL,
                                                          (__bridge void * _Nullable)(self),
                                                          &flags
                                                          );
    
    if (statusCode != noErr) {
        NSLog(@"H264: VTCompressionSessionEncodeFrame failed with %d", (int)statusCode);
        VTCompressionSessionInvalidate(self.compressionSession);
        CFRelease(self.compressionSession);
        self.compressionSession = NULL;
        return;
    }
}

- (void)setupVideoSession {
    
    self.frameID = 0;
    
    int width = 480;
    int height = 640;
    
    OSStatus status = VTCompressionSessionCreate(NULL, width, height, kCMVideoCodecType_H264, NULL, NULL, NULL, didCompressH264, (__bridge void *)(self), &_compressionSession);
    
    if (status != 0){
        return ;
    }
    
    // 设置实时编码输出（直播必然是实时输出,否则会有延迟）
    VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
    VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Baseline_AutoLevel);
    
    // 设置关键帧（GOPsize)间隔
    int frameInterval = 10;
    CFNumberRef  frameIntervalRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &frameInterval);
    VTSessionSetProperty(self.compressionSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, frameIntervalRef);
    
    // 设置期望帧率(每秒多少帧,如果帧率过低,会造成画面卡顿)
    int fps = 30;
    CFNumberRef fpsRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &fps);
    VTSessionSetProperty(self.compressionSession, kVTCompressionPropertyKey_ExpectedFrameRate, fpsRef);
    
    // 设置码率(码率: 编码效率, 码率越高,则画面越清晰, 如果码率较低会引起马赛克 --> 码率高有利于还原原始画面,但是也不利于传输)
    int bitRate = width * height * 3 * 4 * 8;
    CFNumberRef bitRateRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &bitRate);
    VTSessionSetProperty(self.compressionSession, kVTCompressionPropertyKey_AverageBitRate, bitRateRef);
    
    // 设置码率，均值，单位是byte
    int bitRateLimit = width * height * 3 * 4;
    CFNumberRef bitRateLimitRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &bitRateLimit);
    VTSessionSetProperty(self.compressionSession, kVTCompressionPropertyKey_DataRateLimits, bitRateLimitRef);
    
    VTCompressionSessionPrepareToEncodeFrames(_compressionSession);
}

void didCompressH264(void *outputCallbackRefCon, void *sourceFrameRefCon, OSStatus status, VTEncodeInfoFlags infoFlags, CMSampleBufferRef sampleBuffer) {
    
    if (status != 0) {
        return;
    }
    
    if (!CMSampleBufferDataIsReady(sampleBuffer)) {
        return;
    }
    SPVideoEncoder* encoder = (__bridge SPVideoEncoder *)outputCallbackRefCon;
    
    bool keyframe = !CFDictionaryContainsKey( (CFArrayGetValueAtIndex(CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true), 0)), kCMSampleAttachmentKey_NotSync);
    // 判断当前帧是否为关键帧
    // 获取sps & pps数据
    if (keyframe)
    {
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        size_t spsSize, spsCount;
        const uint8_t *sparameterSet;
        OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &sparameterSet, &spsSize, &spsCount, 0 );
        if (statusCode == noErr)
        {
            // Found sps and now check for pps
            size_t ppsSize, ppsCount;
            const uint8_t *pparameterSet;
            OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &pparameterSet, &ppsSize, &ppsCount, 0 );
            if (statusCode == noErr)
            {
                // Found pps
                NSData *sps = [NSData dataWithBytes:sparameterSet length:spsSize];
                NSData *pps = [NSData dataWithBytes:pparameterSet length:ppsSize];
                if (encoder)
                {
                    [encoder gotSpsPps:sps pps:pps];
                }
            }
        }
    }
    
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t length, totalLength;
    char *dataPointer;
    OSStatus statusCodeRet = CMBlockBufferGetDataPointer(dataBuffer, 0, &length, &totalLength, &dataPointer);
    if (statusCodeRet == noErr) {
        size_t bufferOffset = 0;
        static const int AVCCHeaderLength = 4; // 返回的nalu数据前四个字节不是0001的startcode，而是大端模式的帧长度length
        
        // 循环获取nalu数据
        while (bufferOffset < totalLength - AVCCHeaderLength) {
            uint32_t NALUnitLength = 0;
            // Read the NAL unit length
            memcpy(&NALUnitLength, dataPointer + bufferOffset, AVCCHeaderLength);
            
            // 从大端转系统端
            NALUnitLength = CFSwapInt32BigToHost(NALUnitLength);
            
            NSData* data = [[NSData alloc] initWithBytes:(dataPointer + bufferOffset + AVCCHeaderLength) length:NALUnitLength];
            [encoder gotEncodedData:data];
            
            // Move to the next NAL unit in the block buffer
            bufferOffset += AVCCHeaderLength + NALUnitLength;
        }
    }
}

- (void)gotSpsPps:(NSData *)sps pps:(NSData *)pps {
    const char bytes[] = "\x00\x00\x00\x01";
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:4];
    [self.fileWriter writeData:ByteHeader toPath:self.filePath];
    [self.fileWriter writeData:sps toPath:self.filePath];
    [self.fileWriter writeData:ByteHeader toPath:self.filePath];
    [self.fileWriter writeData:pps toPath:self.filePath];
}

- (void)gotEncodedData:(NSData*)data {
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1;     //string literals have implicit trailing '\0'
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
    
    [self.fileWriter writeData:ByteHeader toPath:self.filePath];
    [self.fileWriter writeData:data toPath:self.filePath];
}

@end
