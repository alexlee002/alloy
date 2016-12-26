//
//  SafeBlocksChain.m
//  patchwork
//
//  Created by Alex Lee on 7/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "SafeBlocksChain.h"
#import "UtilitiesHeader.h"
#import "ALOCRuntime.h"
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

static Class fakeBlocksChainClass(Class forClass) {
    if (forClass == nil) {
        return Nil;
    }

    Protocol *fakeProtocol = fakeBlocksChainProtocol();
    if (class_conformsToProtocol(forClass, fakeProtocol)) {
        return forClass;
    }

    const char *classname =
        [[NSStringFromClass(forClass) stringByAppendingString:@"_ALBlocksChainFakeClass"] UTF8String];

    __block Class fakeclass = Nil;
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

id instanceOfFakeBlocksChainClass(Class srcClass, NSString *file, NSInteger line, NSString *funcName,
                                  NSArray<NSString *> *stack) {
    Class cls = fakeBlocksChainClass(srcClass);
    if (cls != Nil) {
        id fakeObj = [[cls alloc] init];

        IMP descIMP = imp_implementationWithBlock(^NSString *(__unsafe_unretained id obj) {
            NSMutableString *desc = [NSMutableString string];
            [desc appendFormat:
                      @"*** Found nil object (expected type: %@) in blocks-chain expression, first occurred in:\n",
                      srcClass];
            [desc appendFormat:@"    %@ (%@:%ld)\n", funcName, [stringValue(file) lastPathComponent], (long) line];

            [desc appendString:@"*** Backtrace:\n{\n"];
            for (NSString *frame in stack) {
                [desc appendFormat:@"    %@\n", frame];
            }
            [desc appendString:@"}"];

            return desc;
        });

        Method descMethod = class_getInstanceMethod(srcClass, @selector(description));
        method_setImplementation(descMethod, descIMP);
        return fakeObj;
    }
    return nil;
}

@implementation NSObject(SafeBlocksChain)

- (BOOL)isValidBlocksChainObject {
    return ![self conformsToProtocol:fakeBlocksChainProtocol()];
}

- (__kindof id (^)())BLOCKS_CHAIN_END {
    return ^id {
        return ObjIsValidBlocksChainObject(self) ? self : nil;
    };
}

@end

