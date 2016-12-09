//
//  SafeBlocksChain.h
//  patchwork
//
//  Created by Alex Lee on 7/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALOCRuntime.h"

extern Class fakeBlocksChainClass(Class forClass);

#define SafeBlocksChainObj(obj, CLASS)  ((CLASS *)((obj) ?: [[fakeBlocksChainClass(CLASS.class) alloc]init]))

#define ValidBlocksChainObjectOrReturn(obj, returnExp)  \
    if (![(obj) isValidBlocksChainObject]) {            \
        return (returnExp);                             \
    }

@interface NSObject (SafeBlocksChain)

- (BOOL)isValidBlocksChainObject;

- (__kindof id (^)())BLOCKS_CHAIN_END;

@end
