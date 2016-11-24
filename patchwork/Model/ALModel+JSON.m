//
//  ALModel.m
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALModel+JSON.h"
#import "YYModel.h"
#import "BlocksKit.h"
#import "NSString+Helper.h"
#import "BlocksKitExtension.h"
#import "NSArray+ArrayExtensions.h"
#import "ALOCRuntime.h"

#import <objc/message.h>
#import <objc/runtime.h>


NS_ASSUME_NONNULL_BEGIN


#pragma mark -

@implementation ALCustomTransformMethodInfo
@end

////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation ALModel(JSON)

#pragma mark - ivar associations

static const void * const kCustomToJSONTransformers = &kCustomToJSONTransformers;
- (void)setCustomToJSONTransformers:(nullable NSDictionary<NSString *, ModelCustomTransformToJSON> *)transformers {
    objc_setAssociatedObject(self, kCustomToJSONTransformers, transformers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSDictionary<NSString *, ModelCustomTransformToJSON> *)customToJSONTransformers {
    return objc_getAssociatedObject(self, kCustomToJSONTransformers);
}

#pragma mark JSON -> Model
//json: `NSDictionary`, `NSString` or `NSData`.
+ (nullable instancetype)modelWithJSON:(id)json {
    return [self yy_modelWithJSON:json];
}

- (nullable instancetype)initWithJSON:(id)json {
    self = [super init];
    if (self && [self yy_modelSetWithJSON:json]) {
        return self;
    }
    return nil;
}

- (BOOL)modelSetWithJSON:(id)json {
    return [self yy_modelSetWithJSON:json];
}

+ (nullable NSArray *)modelArrayWithJSON:(id)json {
    return [NSArray yy_modelArrayWithClass:self json:json];
}

+ (nullable NSDictionary *)modelDictionaryWithJSON:(id)json {
    return [NSDictionary yy_modelDictionaryWithClass:self json:json];
}

#pragma mark Model -> JSON
- (nullable id)modelToJSONObject {
    return [self yy_modelToJSONObject];
}

- (nullable id)modelToJSONObjectWithCustomTransformers:
    (nullable NSDictionary<NSString *, ModelCustomTransformToJSON> *)customTransformers {
    
    [self setCustomToJSONTransformers:customTransformers];
    id json = [self yy_modelToJSONObject];
    [self setCustomToJSONTransformers:nil];
    return json;
}

- (nullable NSData *)modelToJSONData {
    return [self yy_modelToJSONData];
}

- (nullable NSData *)modelToJSONDataWithCustomTransformers:
    (nullable NSDictionary<NSString *, ModelCustomTransformToJSON> *)customTransformers {
    
    [self setCustomToJSONTransformers:customTransformers];
    id json = [self yy_modelToJSONData];
    [self setCustomToJSONTransformers:nil];
    return json;
}

- (nullable NSString *)modelToJSONString {
    return [self yy_modelToJSONString];
}

- (nullable NSString *)modelToJSONStringWithCustomTransformers:
    (nullable NSDictionary<NSString *, ModelCustomTransformToJSON> *)customTransformers {
    
    [self setCustomToJSONTransformers:customTransformers];
    id json = [self yy_modelToJSONString];
    [self setCustomToJSONTransformers:nil];
    return json;
}

#pragma mark -

- (nullable NSArray<NSString *> *)mappedKeysForProperty:(NSString *)propertyName {
    YYClassInfo *classInfo = [YYClassInfo classInfoWithClass:self.class];
    return [self _mappedKeyForProperty:classInfo.propertyInfos[propertyName]];
}

- (nullable NSArray<NSString *>*)_mappedKeyForProperty:(YYClassPropertyInfo *)property {
    if (property.name.length == 0) {
        return nil;
    }
    if ([self.class respondsToSelector:@selector(modelCustomPropertyMapper)]) {
        NSDictionary *mapper = [self.class modelCustomPropertyMapper];
        id keys = mapper[property.name];
        if ([keys isKindOfClass:[NSArray class]]) {
            return (NSArray *)keys;
        }
        return @[ [keys stringify] ?: property.name ];
    }
    return @[property.name];
}

#pragma mark -
- (NSString *)modelDescription {
    return [self yy_modelDescription];
}

- (instancetype)copyModel {
    return [self yy_modelCopy];
}


#pragma mark - YYModel protocol

+ (nullable NSArray<NSString *> *)modelPropertyBlacklist {
    return [ALOCRuntime propertiesOfProtocol:@protocol(NSObject)].allKeys;
}

- (nullable NSDictionary<NSString *, NSArray<ALCustomTransformMethodInfo *> *> *)modelCustomFromJSONTransformers {
    static NSDictionary<NSString *, NSArray<ALCustomTransformMethodInfo *> *> *customTransformers;
    
    static __weak id methodInfos = nil;
    static dispatch_semaphore_t lock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lock = dispatch_semaphore_create(1);
    });
    
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    YYClassInfo *classInfo = [YYClassInfo classInfoWithClass:self.class];
    if (methodInfos != classInfo.methodInfos) {
        methodInfos = classInfo.methodInfos;
        customTransformers = [self customModelPropertySetters];
    }
    dispatch_semaphore_signal(lock);
    return customTransformers;
}

- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic {
    [[self modelCustomFromJSONTransformers]
        bk_each:^(NSString *propertyName, NSArray<ALCustomTransformMethodInfo *> *transformers) {
            NSArray<NSString *> *keys = [self mappedKeysForProperty:propertyName];
            id value = [self valueForKeys:keys OfDictionary:dic];
            if (value == nil) {
                return;
            }
            [transformers bk_each:^(ALCustomTransformMethodInfo *info) {
                if ([value isKindOfClass:info->_classType]) {
                    ((void (*)(id, SEL, id))(void *) objc_msgSend)(self, info->_selector, value);
                }
            }];
        }];

    return YES;
}

- (BOOL)modelCustomTransformToDictionary:(NSMutableDictionary *)dic {
    [[self customToJSONTransformers] bk_each:^(NSString *propertyName, ModelCustomTransformToJSON block) {
        NSString *key = [self mappedKeysForProperty:propertyName].firstObject;
        if ((id)block != NSNull.null && !isEmptyString(key)) {
            dic[key] = block(propertyName/*, [self valueForKey:propertyName]*/);
        }
    }];
    return YES;
}

#pragma mark -

- (nullable id)valueForKeys:(NSArray<NSString *> *)keys OfDictionary:(NSDictionary *)dict {
    for (NSString *key in keys) {
        id value = [dict valueForKeyPath:key];
        if (value != nil) {
            return value;
        }
    }
    return nil;
}

- (nullable NSDictionary<NSString *, NSArray<ALCustomTransformMethodInfo *> *> *)customModelPropertySetters {
    static NSRegularExpression *regexp = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        regexp = [NSRegularExpression
            regularExpressionWithPattern:@"modelCustomTransform([_\\w][_\\w\\d]+)From([_\\w][_\\w\\d]+):"
                                 options:0
                                   error:nil];
    });

    NSMutableDictionary<NSString *, NSArray<ALCustomTransformMethodInfo *> *> *customTransformers =
        [NSMutableDictionary dictionary];
    YYClassInfo *classInfo = [YYClassInfo classInfoWithClass:self.class];

    [classInfo.methodInfos bk_each:^(NSString *selector, YYClassMethodInfo *m) {
        NSTextCheckingResult *result =
            [regexp firstMatchInString:selector options:0 range:NSMakeRange(0, selector.length)];
        if (result && result.range.length == selector.length && result.numberOfRanges == 3) {
            NSString *propertyName = stringOrEmpty([selector substringWithRange:[result rangeAtIndex:1]]);
            propertyName           = [propertyName stringByLowercaseFirst];
            
            Class classType = NSClassFromString(stringOrEmpty([selector substringWithRange:[result rangeAtIndex:2]]));
            YYClassPropertyInfo *property = classInfo.propertyInfos[propertyName];
            if (property != nil && classType != nil) {
                ALCustomTransformMethodInfo *info = [[ALCustomTransformMethodInfo alloc] init];
                info->_selector                   = m.sel;
                info->_classType                  = classType;
                info->_property                   = property;

                NSMutableArray *array = (NSMutableArray *) customTransformers[propertyName];
                if (array == nil) {
                    array                            = [NSMutableArray array];
                    customTransformers[propertyName] = array;
                }
                [array addObject:info];
            }
        }
    }];

    return [customTransformers bk_map:^NSArray<ALCustomTransformMethodInfo *> *(
                                   NSString *propertyName, NSArray<ALCustomTransformMethodInfo *> *transformers) {
        return [transformers sortedArrayUsingComparator:^NSComparisonResult(ALCustomTransformMethodInfo *_Nonnull obj1,
                                                                            ALCustomTransformMethodInfo *_Nonnull obj2) {
            return [obj1->_classType isSubclassOfClass:obj2->_classType] ? NSOrderedAscending : NSOrderedDescending;
        }];
    }];
}

@end

NS_ASSUME_NONNULL_END

