//
//  ALLock.h
//  patchwork
//
//  Created by Alex Lee on 24/11/2016.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

extern void with_gcd_semaphore(dispatch_semaphore_t dsema, dispatch_time_t timeout, void(^block)());
extern void with_lock(NSLock *lock, void (^block)());
