//
//  _ALModelHelper.h
//  alloy
//
//  Created by Alex Lee on 06/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "_ALModelMeta.h"

NS_ASSUME_NONNULL_BEGIN

OBJC_EXPORT BOOL _ALModelKVCSetValueForProperty(__unsafe_unretained id model,
                                                __unsafe_unretained id value,
                                                __unsafe_unretained _ALModelPropertyMeta *meta);

OBJC_EXPORT NSNumber *_Nullable _ALModelCreateNumberFromProperty(__unsafe_unretained id model,
                                                                 __unsafe_unretained _ALModelPropertyMeta *meta);

OBJC_EXPORT NSNumber *_Nullable _YYNSNumberCreateFromID(__unsafe_unretained id value);

OBJC_EXPORT void _ALModelSetNumberToProperty(__unsafe_unretained id model,
                                             __unsafe_unretained NSNumber *num,
                                             __unsafe_unretained _ALModelPropertyMeta *meta);

NS_ASSUME_NONNULL_END
