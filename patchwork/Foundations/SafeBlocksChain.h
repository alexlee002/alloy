//
//  SafeBlocksChain.h
//  patchwork
//
//  Created by Alex Lee on 7/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

extern Class fakeClass             (Class forClass);
extern BOOL  isValidChainingObject (id obj);

#define SafeBlocksChainObj(obj, TYPE)      ((TYPE *)((obj) ?: [[fakeClass(TYPE.class) alloc]init]))

#define ReturnSafeObj(obj, TYPE)                \
    if (!isValidChainingObject((obj))) {        \
        return SafeBlocksChainObj((obj), TYPE); \
    }

#define VerifyChainingObjAndReturn(obj, returnExp)  \
    if (!isValidChainingObject((obj))) {            \
        return (returnExp);                         \
    }

#define VerifyChainingObjAndReturnVoid(obj) \
    if (!isValidChainingObject((obj))) {    \
        return;                             \
    }


@interface NSObject (SafeBlocksChain)

- (__kindof id (^)())end;

- (__kindof NSObject *(^)())consoleLog;
@end
