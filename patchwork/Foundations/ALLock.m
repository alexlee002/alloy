//
//  ALLock.m
//  patchwork
//
//  Created by Alex Lee on 24/11/2016.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALLock.h"
#import "ALUtilitiesHeader.h"

AL_FORCE_INLINE void with_gcd_semaphore(dispatch_semaphore_t dsema, dispatch_time_t timeout, void(^block)()) {
    dispatch_semaphore_wait(dsema, timeout);
    ALSafeInvokeBlock(block);
    dispatch_semaphore_signal(dsema);
}

AL_FORCE_INLINE void with_lock(NSLock *lock, void (^block)()) {
    [lock lock];
    ALSafeInvokeBlock(block);
    [lock unlock];
}

