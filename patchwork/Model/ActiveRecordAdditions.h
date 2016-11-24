//
//  ActiveRecordAdditions.h
//  patchwork
//
//  Created by Alex Lee on 21/11/2016.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#ifndef ActiveRecordAdditions_h
#define ActiveRecordAdditions_h
#import "ALOCRuntime.h"


#define validatePropertyColumnMappings(cls, propNames, retVal)  \
    NSDictionary *columns = [(cls) columns];                    \
    for (NSString *name in (propNames)) {                       \
        if (columns[(name)] == nil) {                           \
            NSAssert(NO, @"*** [%@] no column mapped to property: [%@]",(cls), (name)); \
            return retVal;                                      \
        }                                                       \
    }

#define validateModelRecordBinding(model, retVal)               \
    if (![(model) isModelFromDB]) {                             \
        NSAssert(NO, @"[%@] should be save to database first!", (model).class);         \
        return retVal;                                          \
    }


#pragma mark - model relationships

typedef NS_ENUM(NSInteger, ALARDependency) {
    ALARDependencyDefault = 0,
    ALARDependencyDelete,
};

//#define BELONGS_TO(model_class, getter, dependency)     \



#endif /* ActiveRecordAdditions_h */
    

