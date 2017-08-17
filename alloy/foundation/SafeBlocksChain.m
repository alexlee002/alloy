//
//  SafeBlocksChain.m
//  patchwork
//
//  Created by Alex Lee on 7/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "SafeBlocksChain.h"
#import "ALUtilitiesHeader.h"
#import "ALOCRuntime.h"
#import "NSString+ALHelper.h"
#import "ALLogger.h"
#import "ALLock.h"


static const char *kALBlocksChainFakeObjectProtocolName   = "__ALBlocksChainFakeObjectProtocol";
static NSString * const kALBlocksChainFakeChassNamePrefix = @"__ALBlocksChainFakeClass_$_";

static Protocol *__fakeBlocksChainProtocol() {
    static Protocol *protocol = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        protocol = objc_getProtocol(kALBlocksChainFakeObjectProtocolName);
        if (protocol == nil) {
            protocol = objc_allocateProtocol(kALBlocksChainFakeObjectProtocolName);
            if (protocol) {
                objc_registerProtocol(protocol);
            }
        }
    });
    return protocol;
}

static Class __fakeBlocksChainClass(Class forClass) {
    if (forClass == nil) {
        return Nil;
    }

    Protocol *fakeProtocol = __fakeBlocksChainProtocol();
    if (class_conformsToProtocol(forClass, fakeProtocol)) {
        return forClass;
    }

    const char *classname =
        [[@"__ALBlocksChainFakeClass_$_" stringByAppendingString:NSStringFromClass(forClass)] UTF8String];

    __block Class fakeclass = Nil;
    al_static_gcd_semaphore_def(sem, 1);
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

id al_instanceOfFakeBlocksChainClass(Class srcClass, NSString *file, NSInteger line, NSString *funcName,
                                     NSArray<NSString *> *stack) {
    Class cls = __fakeBlocksChainClass(srcClass);
    if (cls != Nil) {
        id fakeObj = [[cls alloc] init];
#if DEBUG
        IMP descIMP = imp_implementationWithBlock(^NSString *(__unsafe_unretained id obj) {
            NSMutableString *desc = [NSMutableString string];
            [desc appendFormat:
                      @"*** Found nil object (expected type: %@) in blocks-chain expression, first occurred in:\n",
                      srcClass];
            [desc appendFormat:@"    %@ (%@:%ld)\n", funcName, [al_stringValue(file) lastPathComponent], (long) line];

            [desc appendString:@"*** Backtrace:\n{\n"];
            for (NSString *frame in stack) {
                [desc appendFormat:@"    %@\n", frame];
            }
            [desc appendString:@"}"];

            return desc;
        });

        Method descMethod = class_getInstanceMethod(srcClass, @selector(description));
        method_setImplementation(descMethod, descIMP);
#endif
        return fakeObj;
    }
    return nil;
}

@implementation NSObject(SafeBlocksChain)

- (BOOL)al_isValidBlocksChainObject {
    //return ![self conformsToProtocol:__fakeBlocksChainProtocol()];
    //According to performance test, It seems that comparing class name is faster than checking protocol.
    return ![NSStringFromClass(self.class) hasPrefix:kALBlocksChainFakeChassNamePrefix];
}

- (__kindof id (^)(void))BLOCKS_CHAIN_END {
    return ^id {
        return al_objIsValidBlocksChainObject(self) ? self : nil;
    };
}

@end

