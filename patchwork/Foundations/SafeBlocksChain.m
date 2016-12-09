//
//  SafeBlocksChain.m
//  patchwork
//
//  Created by Alex Lee on 7/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "SafeBlocksChain.h"
#import "UtilitiesHeader.h"
#import <objc/runtime.h>
#import "NSString+Helper.h"
#import "ALLogger.h"
#import "ALLock.h"


static NSString * const kFakeChainingObjectProtocolName = @"__AL_BlocksChainFakeObjectProtocol";

static Protocol *fakeBlocksChainProtocol() {
    const char *protochlCName = [kFakeChainingObjectProtocolName UTF8String];
    
    __block Protocol *protocol = nil;
    static_gcd_semaphore(sem, 1);
    with_gcd_semaphore(sem, DISPATCH_TIME_FOREVER, ^{
        if ((protocol = objc_getProtocol(protochlCName)) != nil) {
            return;
        }
        protocol = objc_allocateProtocol(protochlCName);
        if (protocol) {
            objc_registerProtocol(protocol);
        }
    });
    
    return protocol;
}


Class fakeBlocksChainClass(Class forClass) {
    if (forClass == nil) {
        return nil;
    }
    
    Protocol *fakeProtocol = fakeBlocksChainProtocol();
    if (class_conformsToProtocol(forClass, fakeProtocol)) {
        return forClass;
    }
    
    const char *classname = [[NSStringFromClass(forClass) stringByAppendingString:@"_ALFakeBlocksChainClass"] UTF8String];
   
    __block Class fakeclass = nil;
    static_gcd_semaphore(sem, 1);
    with_gcd_semaphore(sem, DISPATCH_TIME_FOREVER, ^{
        if ((fakeclass = objc_getClass(classname)) != nil) {
            return;
        }
        
        fakeclass = objc_allocateClassPair(forClass, classname, 0);
        if (fakeclass != Nil) {
            class_addProtocol(fakeclass, fakeProtocol);
            objc_registerClassPair(fakeclass);
        }
    });
    return fakeclass;
}


@implementation NSObject(SafeBlocksChain)

- (BOOL)isValidBlocksChainObject {
    return ![self conformsToProtocol:fakeBlocksChainProtocol()];
}

- (__kindof id (^)())BLOCKS_CHAIN_END {
    return ^id {
        return [self isValidBlocksChainObject] ? self : nil;
    };
}

@end

