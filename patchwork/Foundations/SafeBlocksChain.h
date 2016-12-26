//
//  SafeBlocksChain.h
//  patchwork
//
//  Created by Alex Lee on 7/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALOCRuntime.h"

NS_ASSUME_NONNULL_BEGIN

//extern Class fakeBlocksChainClass(Class forClass);
extern id _Nullable instanceOfFakeBlocksChainClass(Class srcClass, NSString *file, NSInteger line, NSString *funcName,
                                                      NSArray<NSString *> *stack);

#define SafeBlocksChainObj(obj, CLASS)  ((CLASS *)((obj) ?: \
    instanceOfFakeBlocksChainClass([CLASS class],           \
    (__bridge NSString *)CFSTR(__FILE__),                   \
    __LINE__,                                               \
    [NSString stringWithUTF8String:__PRETTY_FUNCTION__],    \
    backtraceStack(10)) ))

#define ValidBlocksChainObjectOrReturn(obj, returnExp)  \
    if (![(obj) isValidBlocksChainObject]) {            \
        return (returnExp);                             \
    }

#define ObjIsValidBlocksChainObject(obj)                \
    ({                                                  \
        BOOL ret = [(obj) isValidBlocksChainObject];    \
        if (!ret) {                                     \
            ALLogError(@"%@", (obj));                   \
        }                                               \
        ret;                                            \
    })


@interface NSObject (SafeBlocksChain)

- (BOOL)isValidBlocksChainObject;

- (__kindof id (^)())BLOCKS_CHAIN_END;

@end

NS_ASSUME_NONNULL_END
