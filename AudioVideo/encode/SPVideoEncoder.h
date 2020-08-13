//
//  SPVideoEncoder.h
//  AudioVideo
//
//  Created by 王杰 on 2020/8/13.
//  Copyright © 2020 raintai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>

NS_ASSUME_NONNULL_BEGIN

@interface SPVideoEncoder : NSObject
- (instancetype)initWithFilePath:(NSString *)filePath;
- (void)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer;
@end

NS_ASSUME_NONNULL_END
