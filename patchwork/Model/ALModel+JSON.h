//
//  ALModel.h
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALModel_Define.h"
#import "YYModel.h"

NS_ASSUME_NONNULL_BEGIN

// custom transform model's property value to JSON value
typedef id _Nullable (^ModelCustomTransformToJSON)(NSString *_Nonnull propertyName);

@interface ALCustomTransformMethodInfo : NSObject {
    @package
    YYClassPropertyInfo *_property;
    SEL                  _selector;
    Class                _classType;
}
@end

@interface ALModel (JSON) <YYModel>

#pragma mark - model copy


#pragma mark JSON -> Model
+ (nullable instancetype)modelWithJSON:(id)json;
- (nullable instancetype)initWithJSON:(id)json;

- (BOOL)modelSetWithJSON:(id)json;

+ (nullable NSArray *)modelArrayWithJSON:(id)json;
+ (nullable NSDictionary *)modelDictionaryWithJSON:(id)json;
- (nullable NSDictionary<NSString *, NSArray<ALCustomTransformMethodInfo *> *> *)modelCustomFromJSONTransformers;

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


@end

NS_ASSUME_NONNULL_END

