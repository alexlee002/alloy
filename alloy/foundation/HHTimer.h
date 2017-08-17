//
//  HHTimer.h
//  BusinessLayer
//
//  Created by lingaohe on 3/5/14.
//  Copyright (c) 2014 Baidu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HHTimer : NSObject

+ (HHTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)seconds
                              dispatchQueue:(dispatch_queue_t)queue
                                      block:(dispatch_block_t)block
                                   userInfo:(nullable id)userInfo
                                    repeats:(BOOL)yesOrNo;

- (void)fire;
- (void)invalidate;

- (BOOL)isValid;
- (id)userInfo;
@end

NS_ASSUME_NONNULL_END
