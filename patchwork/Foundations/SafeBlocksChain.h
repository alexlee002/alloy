//
//  SafeBlocksChain.h
//  patchwork
//
//  Created by Alex Lee on 7/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALOCRuntime.h"

extern Class fakeClass             (Class forClass);

#define SafeBlocksChainObj(obj, TYPE)      ((TYPE *)((obj) ?: [[fakeClass(TYPE.class) alloc]init]))

#define ValidBlocksChainObjectOrReturn(obj, returnExp)  \
    if (![(obj) isValidBlocksChainObject]) {            \
        return (returnExp);                             \
    }


////TODO: deprecated
//extern BOOL  isValidChainingObject (id obj);
//
////TODO: deprecated
//#define ReturnSafeObj(obj, TYPE)                \
//    if (!isValidChainingObject((obj))) {        \
//        return SafeBlocksChainObj((obj), TYPE); \
//    }
////TODO: deprecated
//#define VerifyChainingObjAndReturn(obj, returnExp)  \
//    if (!isValidChainingObject((obj))) {            \
//        return (returnExp);                         \
//    }
////TODO: deprecated
//#define VerifyChainingObjAndReturnVoid(obj) \
//    if (!isValidChainingObject((obj))) {    \
//        return;                             \
//    }


@interface NSObject (SafeBlocksChain)

- (BOOL)isValidBlocksChainObject;

- (__kindof id (^)())end;

- (__kindof NSObject *(^)())consoleLog;
@end
