//
//  ALDBColumnInfo.h
//  patchwork
//
//  Created by Alex Lee on 2/19/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UtilitiesHeader.h"

NS_ASSUME_NONNULL_BEGIN

@class YYClassPropertyInfo;
@interface ALDBColumnInfo: NSObject
@property(PROP_ATOMIC_DEF, strong)            YYClassPropertyInfo *property;
@property(PROP_ATOMIC_DEF, copy)              NSString            *name;
@property(PROP_ATOMIC_DEF, copy)              NSString            *dataType;
@property(PROP_ATOMIC_DEF, copy, nullable)    NSString            *extra;

- (NSString *)columnDefine;

@end

NS_ASSUME_NONNULL_END