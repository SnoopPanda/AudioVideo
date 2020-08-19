//
//  SPFileWriter.m
//  AudioVideo
//
//  Created by 王杰 on 2020/8/13.
//  Copyright © 2020 raintai. All rights reserved.
//

#import "SPFileWriter.h"

@interface SPFileWriter ()
@property (nonatomic,strong) NSLock *lock;
@end

@implementation SPFileWriter

- (void)writeBytes:(void *)bytes len:(NSUInteger)len toPath:(NSString *)path
{
    NSData *data = [NSData dataWithBytes:bytes length:len];
    [self writeData:data toPath:path];
}

- (void)writeData:(NSData *)data toPath:(NSString *)path
{
    [self.lock lock];
    
    NSString *savePath = path;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:savePath] == false)
    {
        [[NSFileManager defaultManager] createFileAtPath:savePath contents:nil attributes:nil];
    }
    NSFileHandle * handle = [NSFileHandle fileHandleForWritingAtPath:savePath];
    [handle seekToEndOfFile];
    [handle writeData:data];
    
    [self.lock unlock];
}

- (NSLock *)lock
{
    if (_lock == nil)
    {
        _lock = [NSLock new];
    }
    return _lock;
}

@end
