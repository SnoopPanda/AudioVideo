//
//  SPAudioEncoder.m
//  AudioVideo
//
//  Created by 王杰 on 2020/8/13.
//  Copyright © 2020 raintai. All rights reserved.
//

#import "SPAudioEncoder.h"
#import <AVFoundation/AVFoundation.h>
#import "lame.h"
#import "SPFileWriter.h"

@interface SPAudioEncoder ()
{
    uint8_t *_aacBuffer;
    NSUInteger _aacBufferSize;
    char *_pcmBuffer;
    size_t _pcmBufferSize;
    
    AudioConverterRef _audioConverter;
    dispatch_queue_t _encoderQueue;
    
    lame_t _lameClient;
}

@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, assign) SPAudioType audioType;
@property (nonatomic, strong) SPFileWriter *fileWriter;
@end

@implementation SPAudioEncoder

- (void)dealloc
{
    if (_audioConverter) {
        AudioConverterDispose(_audioConverter);
    }

    free(_aacBuffer);
    
    if (_lameClient)
    {
        lame_close(_lameClient);
    }
}

- (instancetype)initWithExpectType:(SPAudioType)type filePath:(NSString *)filePath {
    if (self = [super init]) {
        
        self.filePath = filePath;
        self.audioType = type;
        self.fileWriter = [[SPFileWriter alloc] init];
        
        _pcmBuffer = NULL;
        _pcmBufferSize = 0;
        
        _encoderQueue = dispatch_queue_create("Audio Encoder Queue", DISPATCH_QUEUE_SERIAL);
        
        switch (self.audioType) {
            case SPAudioTypeAAC:
            {
                _aacBufferSize = 1024;
                _audioConverter = NULL;
                _aacBuffer = malloc(_aacBufferSize * sizeof(uint8_t));
                memset(_aacBuffer, 0, _aacBufferSize);
            }
                break;
            case SPAudioTypeMP3:
            {
                _lameClient = lame_init();
                lame_set_in_samplerate(_lameClient, 44100);
                lame_set_num_channels(_lameClient, 1);
                lame_set_brate(_lameClient, 128);
                lame_init_params(_lameClient);
            }
                break;
                
            default:
                break;
        }
    }
    return self;
}

- (void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    
    CFRetain(sampleBuffer);
    dispatch_async(_encoderQueue, ^{
        if (!self->_audioConverter) {
            [self setupEncoderFromSampleBuffer:sampleBuffer];
        }
        CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
        CFRetain(blockBuffer);
        OSStatus status = CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, &self->_pcmBufferSize, &self->_pcmBuffer);
        NSError *error = nil;
        if (status != kCMBlockBufferNoErr) {
            error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        }
        switch (self.audioType) {
            case SPAudioTypeAAC:
                [self encodeBufferToAAC];
                break;
            case SPAudioTypeMP3:
                [self encodeBufferToMP3];
                break;
                
            default:
                break;
        }
        CFRelease(sampleBuffer);
        CFRelease(blockBuffer);
    });
}

- (void)encodeBufferToMP3 {
    
    int mp3DataSize = (int)_pcmBufferSize;
    
    unsigned char mp3Buffer[mp3DataSize];

    /**
     这里的len / 2，是因为我们录音数据是char *类型的，一个char占一个字节。而这里要传的数据是short *类型的，一个short占2个字节
     
     lame_encode_buffer             //录音数据单声道16位整形用这个方法
     lame_encode_buffer_interleaved //录音数据双声道交错用这个方法
     lame_encode_buffer_float       //录音数据采样深度32位浮点型用这个方法
     */
    int encodedBytes = lame_encode_buffer(_lameClient, _pcmBuffer, _pcmBuffer, (int)_pcmBufferSize/2, mp3Buffer, mp3DataSize);
    
    NSData *data = [[NSData alloc] initWithBytes:mp3Buffer length:encodedBytes];
    [self.fileWriter writeData:data toPath:self.filePath];
}

- (void)encodeBufferToAAC
{
    OSStatus status = 0;
    NSError *error = nil;
    
    memset(_aacBuffer, 0, _aacBufferSize);
    
    AudioBufferList outAudioBufferList = {0};
    outAudioBufferList.mNumberBuffers = 1;
    outAudioBufferList.mBuffers[0].mNumberChannels = 1;
    outAudioBufferList.mBuffers[0].mDataByteSize = (int)_aacBufferSize;
    outAudioBufferList.mBuffers[0].mData = _aacBuffer;
    AudioStreamPacketDescription *outPacketDescription = NULL;
    UInt32 ioOutputDataPacketSize = 1;
    // Converts data supplied by an input callback function, supporting non-interleaved and packetized formats.
    // Produces a buffer list of output data from an AudioConverter. The supplied input callback function is called whenever necessary.
    status = AudioConverterFillComplexBuffer(_audioConverter, inInputDataProc, (__bridge void *)(self), &ioOutputDataPacketSize, &outAudioBufferList, outPacketDescription);
    NSData *data = nil;
    if (status == 0) {
        NSData *rawAAC = [NSData dataWithBytes:outAudioBufferList.mBuffers[0].mData length:outAudioBufferList.mBuffers[0].mDataByteSize];
        NSData *adtsHeader = [self adtsDataForPacketLength:rawAAC.length];
        NSMutableData *fullData = [NSMutableData dataWithData:adtsHeader];
        [fullData appendData:rawAAC];
        data = fullData;
    } else {
        error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
    }
    
    if (!error) {
        [self.fileWriter writeData:data toPath:self.filePath];
    }
}

- (void)setupEncoderFromSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    AudioStreamBasicDescription inAudioStreamBasicDescription = *CMAudioFormatDescriptionGetStreamBasicDescription((CMAudioFormatDescriptionRef)CMSampleBufferGetFormatDescription(sampleBuffer));
    
    [self setupEncoderWithInputAudioStreamDesc:inAudioStreamBasicDescription];
}

- (void)setupEncoderWithInputAudioStreamDesc:(AudioStreamBasicDescription)inputAudioStreamDesc
{
    AudioStreamBasicDescription outAudioStreamBasicDescription = {0}; // 初始化输出流的结构体描述为0. 很重要。
    outAudioStreamBasicDescription.mSampleRate = inputAudioStreamDesc.mSampleRate; // 音频流，在正常播放情况下的帧率。如果是压缩的格式，这个属性表示解压缩后的帧率。帧率不能为0。
    outAudioStreamBasicDescription.mFormatID = kAudioFormatMPEG4AAC; // 设置编码格式
    outAudioStreamBasicDescription.mFormatFlags = kMPEG4Object_AAC_LC; // 无损编码 ，0表示没有
    outAudioStreamBasicDescription.mBytesPerPacket = 0; // 每一个packet的音频数据大小。如果的动态大小，设置为0。动态大小的格式，需要用AudioStreamPacketDescription 来确定每个packet的大小。
    outAudioStreamBasicDescription.mFramesPerPacket = 1024; // 每个packet的帧数。如果是未压缩的音频数据，值是1。动态码率格式，这个值是一个较大的固定数字，比如说AAC的1024。如果是动态大小帧数（比如Ogg格式）设置为0。
    outAudioStreamBasicDescription.mBytesPerFrame = 0; //  每帧的大小。每一帧的起始点到下一帧的起始点。如果是压缩格式，设置为0 。
    outAudioStreamBasicDescription.mChannelsPerFrame = 1; // 声道数
    outAudioStreamBasicDescription.mBitsPerChannel = 0; // 压缩格式设置为0
    outAudioStreamBasicDescription.mReserved = 0; // 8字节对齐，填0.
    AudioClassDescription *description = [self
                                          getAudioClassDescriptionWithType:kAudioFormatMPEG4AAC
                                          fromManufacturer:kAppleHardwareAudioCodecManufacturer]; //软编或者硬编
    
    OSStatus status = AudioConverterNewSpecific(&inputAudioStreamDesc, &outAudioStreamBasicDescription, 1, description, &_audioConverter); // 创建转换器
    if (status != 0) {
        NSLog(@"setup converter: %d", (int)status);
    }
}

- (AudioClassDescription *)getAudioClassDescriptionWithType:(UInt32)type
                                           fromManufacturer:(UInt32)manufacturer
{
    static AudioClassDescription desc;
    
    UInt32 encoderSpecifier = type;
    OSStatus st;
    
    UInt32 size;
    st = AudioFormatGetPropertyInfo(kAudioFormatProperty_Encoders,
                                    sizeof(encoderSpecifier),
                                    &encoderSpecifier,
                                    &size);
    if (st) {
        NSLog(@"error getting audio format propery info: %d", (int)(st));
        return nil;
    }
    
    unsigned int count = size / sizeof(AudioClassDescription);
    AudioClassDescription descriptions[count];
    st = AudioFormatGetProperty(kAudioFormatProperty_Encoders,
                                sizeof(encoderSpecifier),
                                &encoderSpecifier,
                                &size,
                                descriptions);
    if (st) {
        NSLog(@"error getting audio format propery: %d", (int)(st));
        return nil;
    }
    
    for (unsigned int i = 0; i < count; i++) {
        if ((type == descriptions[i].mSubType) &&
            (manufacturer == descriptions[i].mManufacturer)) {
            memcpy(&desc, &(descriptions[i]), sizeof(desc));
            return &desc;
        }
    }
    
    return nil;
}

- (NSData*)adtsDataForPacketLength:(NSUInteger)packetLength
{
    int adtsLength = 7;
    char *packet = malloc(sizeof(char) * adtsLength);
    // Variables Recycled by addADTStoPacket
    int profile = 2;  //AAC LC
    //39=MediaCodecInfo.CodecProfileLevel.AACObjectELD;
    int freqIdx = 4;  //44.1KHz
    int chanCfg = 1;  //MPEG-4 Audio Channel Configuration. 1 Channel front-center
    NSUInteger fullLength = adtsLength + packetLength;
    // fill in ADTS data
    packet[0] = (char)0xFF; // 11111111     = syncword
    packet[1] = (char)0xF9; // 1111 1 00 1  = syncword MPEG-2 Layer CRC
    packet[2] = (char)(((profile-1)<<6) + (freqIdx<<2) +(chanCfg>>2));
    packet[3] = (char)(((chanCfg&3)<<6) + (fullLength>>11));
    packet[4] = (char)((fullLength&0x7FF) >> 3);
    packet[5] = (char)(((fullLength&7)<<5) + 0x1F);
    packet[6] = (char)0xFC;
    NSData *data = [NSData dataWithBytesNoCopy:packet length:adtsLength freeWhenDone:YES];
    return data;
}

#pragma mark - 为转换器提供输入数据的回调

OSStatus inInputDataProc(AudioConverterRef inAudioConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription **outDataPacketDescription, void *inUserData)
{
    SPAudioEncoder *encoder = (__bridge SPAudioEncoder *)(inUserData);
    UInt32 requestedPackets = *ioNumberDataPackets;
    
    size_t copiedSamples = [encoder copyPCMSamplesIntoBuffer:ioData];
    if (copiedSamples < requestedPackets) {
        //PCM 缓冲区还没满
        *ioNumberDataPackets = 0;
        return -1;
    }
    *ioNumberDataPackets = 1;
    
    return noErr;
}

/**
 *  填充PCM到缓冲区
 */
- (size_t)copyPCMSamplesIntoBuffer:(AudioBufferList*)ioData
{
    size_t originalBufferSize = _pcmBufferSize;
    if (!originalBufferSize) {
        return 0;
    }
    ioData->mBuffers[0].mData = _pcmBuffer;
    ioData->mBuffers[0].mDataByteSize = (int)_pcmBufferSize;
    _pcmBuffer = NULL;
    _pcmBufferSize = 0;
    return originalBufferSize;
}

@end
