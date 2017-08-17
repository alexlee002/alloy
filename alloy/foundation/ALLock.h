//
//  ALLock.h
//  patchwork
//
//  Created by Alex Lee on 24/11/2016.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern void with_gcd_semaphore(dispatch_semaphore_t dsema, dispatch_time_t timeout, void(^block)(void));
extern void with_lock(NSLock *lock, void (^block)(void));

NS_ASSUME_NONNULL_END
