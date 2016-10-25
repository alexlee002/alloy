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


static NSString * const kFakeChainingObjectProtocolName = @"FakeChainingObjectProtocol";

Protocol *fakeProtocol() {
    const char *protochlCName = [kFakeChainingObjectProtocolName UTF8String];
    
    Protocol *protocol = objc_getProtocol(protochlCName);
    if (protocol != NULL) {
        return protocol;
    }
    
    LocalDispatchSemaphoreLock_Wait();
    protocol = objc_allocateProtocol(protochlCName);
    if (protocol) {
        objc_registerProtocol(protocol);
    }
    LocalDispatchSemaphoreLock_Signal();
    return protocol;
}


Class fakeClass(Class forClass) {
    if (forClass == nil) {
        return nil;
    }
    const char *classname = [[NSStringFromClass(forClass) stringByAppendingString:@"_ALFakeChainingObject"] UTF8String];
    Class fakeclass = objc_getClass(classname);
    
    if (fakeclass != nil) {
        return fakeclass;
    }
    
    LocalDispatchSemaphoreLock_Wait();
    fakeclass = objc_allocateClassPair(forClass, classname, 0);
    class_addProtocol(fakeclass, fakeProtocol());
    objc_registerClassPair(fakeclass);
    LocalDispatchSemaphoreLock_Signal();
    
    return fakeclass;
}

BOOL isValidChainingObject(id obj) {
    if ([obj conformsToProtocol:fakeProtocol()]) {
        ALLogWarn(@"*** nil value found in chaining expression!!!\nback trace stack:\n%@", backtraceStack(5));
        return NO;
    }
    return obj != nil;
}


@implementation NSObject(SafeBlocksChain)

- (BOOL)isValidBlocksChainObject {
    return ![self conformsToProtocol:fakeProtocol()];
}

- (__kindof id (^)())end {
    return ^id {
        if (!isValidChainingObject(self)) {
            return nil;
        }
        return self;
    };
}

- (__kindof NSObject *(^)())consoleLog {
    return ^id {
        if (isValidChainingObject(self)) {
            NSString *desc = isEmptyString(self.debugDescription) ? self.description : self.debugDescription;
            ALLogVerbose(@"%@", desc);
        } else {
            ALLogVerbose(@"Chaining method object is nil, and it should be of type:[%@]", self.superclass);
        }
        
        return self; //SafeChainingObj(self, typeof(self))
    };
}

@end

