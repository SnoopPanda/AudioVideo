//
//  SPFileWriter.h
//  AudioVideo
//
//  Created by 王杰 on 2020/8/13.
//  Copyright © 2020 raintai. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SPFileWriter : NSObject
- (void)writeBytes:(void *)bytes len:(NSUInteger)len toPath:(NSString *)path;
- (void)writeData:(NSData *)data toPath:(NSString *)path;
@end

NS_ASSUME_NONNULL_END
