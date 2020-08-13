//
//  SPAudioEncoder.h
//  AudioVideo
//
//  Created by 王杰 on 2020/8/13.
//  Copyright © 2020 raintai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>

typedef enum : NSUInteger {
    SPAudioTypePCM,
    SPAudioTypeAAC,
    SPAudioTypeMP3,
} SPAudioType;

NS_ASSUME_NONNULL_BEGIN

@interface SPAudioEncoder : NSObject
- (instancetype)initWithExpectType:(SPAudioType)type filePath:(NSString *)filePath;
- (void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer;
@end

NS_ASSUME_NONNULL_END
