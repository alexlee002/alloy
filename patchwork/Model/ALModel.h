//
//  ALModel.h
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YYClassInfo.h"

NS_ASSUME_NONNULL_BEGIN

//extern NSString * const kInternalObjectPrefix;
typedef id _Nullable (^ModelCustomTransformToJSON)(NSString *_Nonnull propertyName, id _Nullable value);

@interface ALModel : NSObject

#pragma mark - model copy
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

#pragma mark JSON -> Model
+ (nullable instancetype)modelWithJSON:(id)json;
- (nullable instancetype)initWithJSON:(id)json;

- (BOOL)modelSetWithJSON:(id)json;

+ (nullable NSArray *)modelArrayWithJSON:(id)json;
+ (nullable NSDictionary *)modelDictionaryWithJSON:(id)json;

#pragma mark Model -> JSON
- (nullable id)modelToJSONObject;
- (nullable id)modelToJSONObjectWithCustomTransformers:
(nullable NSDictionary<NSString *, ModelCustomTransformToJSON> *)customTransformers;

- (nullable NSData *)modelToJSONData;
- (nullable NSData *)modelToJSONDataWithCustomTransformers:
(nullable NSDictionary<NSString *, ModelCustomTransformToJSON> *)customTransformers;

- (nullable NSString *)modelToJSONString;
- (nullable NSString *)modelToJSONStringWithCustomTransformers:
(nullable NSDictionary<NSString *, ModelCustomTransformToJSON> *)customTransformers;

#pragma mark -

- (nullable NSArray<NSString *> *)mappedKeysForProperty:(NSString *)propertyName;

#pragma mark - supper class method wrapper
- (NSString *)modelDescription;
//- (instancetype)copyModel;


@end

@interface ALModel (ClassMetas)
+ (NSDictionary<NSString *, YYClassPropertyInfo *> *)allModelProperties;
+ (NSDictionary<NSString *, YYClassIvarInfo *> *)allModelIvars;
+ (NSDictionary<NSString *, YYClassMethodInfo *> *)allModelMethods;

+ (BOOL)hasModelProperty:(NSString *)propertyName;
@end


@interface NSObject (ClassMetasExtension)

+ (Class)commonAncestorWithClass:(Class)other;
+ (NSArray<Class> *)ancestorClasses;

+ (NSDictionary<NSString *, YYClassPropertyInfo *> *)allProperties;
+ (NSDictionary<NSString *, YYClassIvarInfo *> *)allIvars;
+ (NSDictionary<NSString *, YYClassMethodInfo *> *)allMethods;

+ (BOOL)hasProperty:(NSString *)propertyName;
@end

NS_ASSUME_NONNULL_END

