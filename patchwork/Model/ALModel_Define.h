//
//  ALModel_Define.h
//  patchwork
//
//  Created by Alex Lee on 2/25/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//for ActiveRecord
extern NSString * const kModelRowidDidChangeNotification;
extern NSString * const kModelRowidOldValueKey;
extern NSString * const kModelRowidNewValueKey;

@interface ALModel : NSObject

@end


@class YYClassPropertyInfo;
@class YYClassIvarInfo;
@class YYClassMethodInfo;

@interface ALModel (ALRuntime) <NSCopying>

/**
 *  Create a new Model instance and copy properties from 'other'
 *  @see "-modelCopyProperties:fromModel:"
 */
+ (nullable instancetype)modelCopyFromModel:(__kindof ALModel *)other;

/**
 *  Create a new Model instance and copy specified properties from 'other'
 *  @see "-modelCopyProperties:fromModel:"
 */
+ (nullable instancetype)modelCopyFromModel:(__kindof ALModel *)other withProperties:(NSArray<NSString *> *)properties;

/**
 *  Create a new Model instance and copy properties from 'other', ignore the specified properties
 *  @see "-modelCopyProperties:fromModel:"
 */
+ (nullable instancetype)modelCopyFromModel:(__kindof ALModel *)other
                          excludeProperties:(NSArray<NSString *> *)properties;

/**
 *  Copy properties' value from &lt; other &gt; model.
 *  Copy rules:
 *      find out the 'last common ancestor' class of the 'self' and 'other' model
 *      ignore the properties that specified by param 'properties' but not belongs to the 'last common ancestor' class
 *      copy properties values
 *
 *  @param properties properties to copy
 *  @param other      model that copy from
 */
- (void)modelCopyProperties:(nullable NSArray<NSString *> *)properties fromModel:(__kindof ALModel *)other;

#pragma mark - bootstraps
+ (NSDictionary<NSString *, YYClassPropertyInfo *> *)allModelProperties;
+ (NSDictionary<NSString *, YYClassIvarInfo *>     *)allModelIvars;
+ (NSDictionary<NSString *, YYClassMethodInfo *>   *)allModelMethods;

+ (BOOL)hasModelProperty:(NSString *)propertyName;

@end

NS_ASSUME_NONNULL_END
