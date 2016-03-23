//
//  HHTimer.m
//  BusinessLayer
//
//  Created by lingaohe on 3/5/14.
//  Copyright (c) 2014 Baidu. All rights reserved.
//

#import "HHTimer.h"
#import "UtilitiesHeader.h"

@interface HHTimer ()
@property(nonatomic, readwrite, copy) dispatch_block_t block;
//@property(nonatomic, readwrite, strong) dispatch_source_t source;
@property(nonatomic, strong) id internalUserInfo;
@end

@implementation HHTimer {
    dispatch_source_t _source;
}

#pragma mark-- Init
+ (HHTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)seconds
                              dispatchQueue:(dispatch_queue_t)queue
                                      block:(dispatch_block_t)block
                                   userInfo:(id)userInfo
                                    repeats:(BOOL)yesOrNo {
    NSParameterAssert(seconds);
    NSParameterAssert(block);

    HHTimer *timer = [[self alloc] init];
    timer.internalUserInfo = userInfo;
    timer.block = block;
    timer->_source = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    uint64_t nsec = (uint64_t)(seconds * NSEC_PER_SEC);
    dispatch_source_set_timer(timer->_source, dispatch_time(DISPATCH_TIME_NOW, nsec), nsec, 0);
    void (^internalBlock)(void) = ^{
        if (!yesOrNo) {
            block();
            [timer invalidate];
        } else {
            block();
        }
    };
    dispatch_source_set_event_handler(timer->_source, internalBlock);
    dispatch_resume(timer->_source);
    return timer;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        ALLogVerbose(@"----- %@ inited! -----", self);
    }
    return self;
}

- (void)dealloc {
    [self invalidate];
    ALLogVerbose(@"~~~~~ %@ DEALLOCED! ~~~~~", self);
}
#pragma mark--Action
- (void)fire {
    self.block();
}

- (void)invalidate {
    if (_source) {
        dispatch_source_cancel(_source);
        #if !__has_feature(objc_arc)
        dispatch_release(_source);
        #endif
        _source = nil;
    }
    self.block = nil;
}

#pragma mark-- State
- (BOOL)isValid {
    return (_source != nil);
}

- (id)userInfo {
    return self.internalUserInfo;
}
@end
