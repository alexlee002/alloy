//
//  ALDBColumnInfo.h
//  patchwork
//
//  Created by Alex Lee on 2/19/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class YYClassPropertyInfo;
@interface ALDBColumnInfo: NSObject
@property(nonatomic, strong)            YYClassPropertyInfo *property;
@property(nonatomic, copy)              NSString            *name;
@property(nonatomic, copy)              NSString            *dataType;
@property(nonatomic, copy, nullable)    NSString            *extra;

- (NSString *)columnDefine;

@end

NS_ASSUME_NONNULL_END