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
extern id _Nullable al_instanceOfFakeBlocksChainClass(Class srcClass, NSString *file, NSInteger line, NSString *funcName,
                                                      NSArray<NSString *> *stack);

#define al_safeBlocksChainObj(obj, CLASS)  ((CLASS *)((obj) ?:  \
    al_instanceOfFakeBlocksChainClass([CLASS class],            \
    (__bridge NSString *)CFSTR(__FILE__),                       \
    __LINE__,                                                   \
    [NSString stringWithUTF8String:__PRETTY_FUNCTION__],        \
    al_backtraceStack(10)) ))

#define al_isValidBlocksChainObjectOrReturn(obj, returnExp)     \
    if (!al_objIsValidBlocksChainObject((obj))) {               \
        return (returnExp);                                     \
    }

#define al_objIsValidBlocksChainObject(obj)                 \
    ({                                                      \
        BOOL ret = [(obj) al_isValidBlocksChainObject];     \
        if (!ret) {                                         \
            ALLogError(@"%@", (obj));                       \
        }                                                   \
        ret;                                                \
    })


@interface NSObject (SafeBlocksChain)

- (BOOL)al_isValidBlocksChainObject;

- (__kindof id (^)(void))BLOCKS_CHAIN_END;

@end

NS_ASSUME_NONNULL_END
