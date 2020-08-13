//
//  SPCaptureView.h
//  AudioVideo
//
//  Created by 王杰 on 2020/8/12.
//  Copyright © 2020 raintai. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SPCaptureView : UIView
- (void)startRunning;
- (void)stopRunning;
- (void)flipCamera;
@end

NS_ASSUME_NONNULL_END
