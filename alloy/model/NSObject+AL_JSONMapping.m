//
//  NSObject+JSONMapping.m
//  patchwork
//
//  Created by Alex Lee on 09/06/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//
//  IMPORTANT:
//  The implementation of JSON & model mapping is very much inspired by YYModel(@link: https://github.com/ibireme/YYModel ).
//  Thanks @Yaoyuan (@link: https://github.com/ibireme )!
//  The copyright of the code from YYModel is reserved by @Yaoyuan.
//

#import "NSObject+AL_JSONMapping.h"
#import "__ALModelHelper.h"
#import "__ALModelMeta+JSONMapping.h"
#import "YYModel.h"
#import "ALUtilitiesHeader.h"
#import <objc/message.h>

/// Get the value with key paths from dictionary
/// The dic should be NSDictionary, and the keyPath should not be nil.
static AL_FORCE_INLINE id YYValueForKeyPath(__unsafe_unretained NSDictionary *dic,
                                            __unsafe_unretained NSArray *keyPaths) {
    id value = nil;
    for (NSUInteger i = 0, max = keyPaths.count; i < max; i++) {
        value = dic[keyPaths[i]];
        if (i + 1 < max) {
            if ([value isKindOfClass:[NSDictionary class]]) {
                dic = value;
            } else {
                return nil;
            }
        }
    }
    return value;
}

/// Get the value with multi key (or key path) from dictionary
/// The dic should be NSDictionary
static AL_FORCE_INLINE id YYValueForMultiKeys(__unsafe_unretained NSDictionary *dic,
                                              __unsafe_unretained NSArray *multiKeys) {
    id value = nil;
    for (NSString *key in multiKeys) {
        if ([key isKindOfClass:[NSString class]]) {
            value = dic[key];
            if (value) break;
        } else {
            value = YYValueForKeyPath(dic, (NSArray *)key);
            if (value) break;
        }
    }
    return value;
}


typedef struct {
    void *modelMeta;  ///< _ALModelJSONMeta
    void *model;      ///< id (self)
    void *dictionary; ///< NSDictionary (json)
} _ModelSetContext;

/**
 Apply function for dictionary, to set the key-value pair to model.
 
 @param _key     should not be nil, NSString.
 @param _value   should not be nil.
 @param _context _context.modelMeta and _context.model should not be nil.
 */
static void ModelSetWithDictionaryFunction(const void *_key, const void *_value, void *_context) {
    _ModelSetContext *context = _context;
    __unsafe_unretained _ALModelJSONMeta *meta = (__bridge _ALModelJSONMeta *)(context->modelMeta);
    __unsafe_unretained _ALPropertyJSONMeta *propertyMeta = [meta->_mapper objectForKey:(__bridge id)(_key)];
    __unsafe_unretained id model = (__bridge id)(context->model);
    while (propertyMeta) {
        _ModelSetValueForProperty(model,
                                 (__bridge __unsafe_unretained id) _value,
                                 propertyMeta->_meta,
                                 propertyMeta->_genericClass,
                                 propertyMeta->_hasCustomClassFromDictionary
                                     ? @selector(modelCustomClassForDictionary:)
                                     : nil);
        propertyMeta = propertyMeta->_next;
    };
}

/**
 Apply function for model property meta, to set dictionary to model.
 
 @param _propertyMeta should not be nil, _YYModelPropertyMeta.
 @param _context      _context.model and _context.dictionary should not be nil.
 */
static void ModelSetWithPropertyMetaArrayFunction(const void *_propertyMeta, void *_context) {
    _ModelSetContext *context = _context;
    __unsafe_unretained NSDictionary *dictionary = (__bridge NSDictionary *)(context->dictionary);
    __unsafe_unretained _ALPropertyJSONMeta *propertyMeta = (__bridge _ALPropertyJSONMeta *)(_propertyMeta);
    
    //TODO: setValueForKey:
    if (!propertyMeta->_meta->_setter) { return; }
    id value = nil;
    
    if (propertyMeta->_mappedToKeyArray) {
        value = YYValueForMultiKeys(dictionary, propertyMeta->_mappedToKeyArray);
    } else if (propertyMeta->_mappedToKeyPath) {
        value = YYValueForKeyPath(dictionary, propertyMeta->_mappedToKeyPath);
    } else {
        value = [dictionary objectForKey:propertyMeta->_mappedToKey];
    }
    
    if (value) {
        __unsafe_unretained id model = (__bridge id)(context->model);
        _ModelSetValueForProperty( model, value, propertyMeta->_meta,
                                  propertyMeta->_genericClass,
                                  propertyMeta->_hasCustomClassFromDictionary ?
                                         @selector(modelCustomClassForDictionary:) : nil);
    }
}

static id ModelToJSONObjectRecursive(NSObject *model);
static NSArray *ModelToJSONObjectWithArray(NSArray *array) {
    if ([NSJSONSerialization isValidJSONObject:array]) {
        return array;
    }
    
    NSMutableArray *newArray = [NSMutableArray array];
    for (id obj in array) {
        if ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSNumber class]]) {
            [newArray addObject:obj];
        } else {
            id jsonObj = ModelToJSONObjectRecursive(obj);
            if (jsonObj && jsonObj != (id) kCFNull) {
                [newArray addObject:jsonObj];
            }
        }
    }
    return newArray;
}

/**
 Returns a valid JSON object (NSArray/NSDictionary/NSString/NSNumber/NSNull),
 or nil if an error occurs.
 
 @param model Model, can be nil.
 @return JSON object, nil if an error occurs.
 */
static id ModelToJSONObjectRecursive(NSObject *model) {
    if (!model || model == (id) kCFNull) {
        return model;
    }
    if ([model isKindOfClass:[NSString class]]) {
        return model;
    }
    if ([model isKindOfClass:[NSNumber class]]) {
        return model;
    }
    
    if ([model isKindOfClass:[NSDictionary class]]) {
        if ([NSJSONSerialization isValidJSONObject:model]) {
            return model;
        }
        
        NSMutableDictionary *newDic = [NSMutableDictionary dictionary];
        [((NSDictionary *) model) enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
            NSString *stringKey = [key isKindOfClass:[NSString class]] ? key : key.description;
            if (!stringKey) {
                return;
            }
            
            id jsonObj = ModelToJSONObjectRecursive(obj);
            if (!jsonObj) {
                jsonObj = (id) kCFNull;
            }
            
            newDic[stringKey] = jsonObj;
        }];
        return newDic;
    }
    
    if ([model isKindOfClass:[NSSet class]]) {
        NSArray *array = ((NSSet *) model).allObjects;
        return ModelToJSONObjectWithArray(array);
    }
    
    if ([model isKindOfClass:[NSArray class]]) {
        return ModelToJSONObjectWithArray((NSArray *) model);
    }
    
    if ([model isKindOfClass:[NSURL class]]) {
        return ((NSURL *) model).absoluteString;
    }
    if ([model isKindOfClass:[NSAttributedString class]]) {
        return ((NSAttributedString *) model).string;
    }
    if ([model isKindOfClass:[NSDate class]]) {
        return [_YYISODateFormatter() stringFromDate:(id) model];
    }
    if ([model isKindOfClass:[NSData class]]) {
        return nil;
    }
    
    _ALModelJSONMeta *modelMeta = [_ALModelJSONMeta metaWithClass:[model class]];
    if (!modelMeta || modelMeta->_allPropertyMetas.count == 0) {
        return nil;
    }
    
    NSMutableDictionary *result                  = [[NSMutableDictionary alloc] initWithCapacity:64];
    __unsafe_unretained NSMutableDictionary *dic = result;  // avoid retain and release in block
    [modelMeta->_mapper enumerateKeysAndObjectsUsingBlock:^(NSString *propertyMappedKey,
                                                            _ALPropertyJSONMeta *jsonPropMeta, BOOL *stop) {
        _ALModelPropertyMeta *propMeta = jsonPropMeta->_meta;
        if (!propMeta || !propMeta->_getter) {
            return;
        }
        
        id value = nil;
        if (propMeta->_isCNumber) {
            value = _ModelCreateNumberFromProperty(model, propMeta);
        } else if (propMeta->_nsType) {
            id v  = ((id(*)(id, SEL))(void *) objc_msgSend)((id) model, propMeta->_getter);
            value = ModelToJSONObjectRecursive(v);
        } else {
            switch (propMeta->_type & YYEncodingTypeMask) {
                case YYEncodingTypeObject: {
                    id v  = ((id(*)(id, SEL))(void *) objc_msgSend)((id) model, propMeta->_getter);
                    value = ModelToJSONObjectRecursive(v);
                    if (value == (id) kCFNull) {
                        value = nil;
                    }
                } break;
                case YYEncodingTypeClass: {
                    Class v = ((Class(*)(id, SEL))(void *) objc_msgSend)((id) model, propMeta->_getter);
                    value   = v ? NSStringFromClass(v) : nil;
                } break;
                case YYEncodingTypeSEL: {
                    SEL v = ((SEL(*)(id, SEL))(void *) objc_msgSend)((id) model, propMeta->_getter);
                    value = v ? NSStringFromSelector(v) : nil;
                } break;
                default:
                    break;
            }
        }
        if (!value) {
            return;
        }
        
        if (jsonPropMeta->_mappedToKeyPath) {
            NSMutableDictionary *superDic = dic;
            NSMutableDictionary *subDic   = nil;
            for (NSUInteger i = 0, max = jsonPropMeta->_mappedToKeyPath.count; i < max; i++) {
                NSString *key = jsonPropMeta->_mappedToKeyPath[i];
                if (i + 1 == max) {  // end
                    if (!superDic[key]) {
                        superDic[key] = value;
                    }
                    break;
                }
                
                subDic = superDic[key];
                if (subDic) {
                    if ([subDic isKindOfClass:[NSDictionary class]]) {
                        subDic        = subDic.mutableCopy;
                        superDic[key] = subDic;
                    } else {
                        break;
                    }
                } else {
                    subDic        = [NSMutableDictionary dictionary];
                    superDic[key] = subDic;
                }
                superDic = subDic;
                subDic   = nil;
            }
        } else {
            if (!dic[jsonPropMeta->_mappedToKey]) {
                dic[jsonPropMeta->_mappedToKey] = value;
            }
        }
    }];
    
    if (modelMeta->_hasCustomTransformToDictionary) {
        BOOL suc = [((id<YYModel>) model) modelCustomTransformToDictionary:dic];
        if (!suc) {
            return nil;
        }
    }
    return result;
}

@implementation NSObject (AL_JSONMapping)

#pragma mark - model json mapping
+ (instancetype)al_modelWithJSON:(id)JSON {
    NSDictionary *dict = [_ALModelHelper dictionaryFromJSON:JSON];
    return [self al_modelWithDictionary:dict];
}

+ (instancetype)al_modelWithDictionary:(NSDictionary *)dictionary {
    if (!dictionary || dictionary == (id) kCFNull) {
        return nil;
    }
    al_guard_or_return([dictionary isKindOfClass:[NSDictionary class]], nil);
    
    Class cls                   = [self class];
    _ALModelJSONMeta *modelMeta = [_ALModelJSONMeta metaWithClass:cls];
    if (modelMeta->_hasCustomClassFromDictionary) {
        cls = [cls modelCustomClassForDictionary:dictionary] ?: cls;
    }
    
    NSObject *one = [[cls alloc] init];
    if ([one al_modelSetWithDictionary:dictionary]) {
        return one;
    }
    return nil;
}

- (BOOL)al_modelSetWithJSON:(id)json {
    NSDictionary *dic = [_ALModelHelper dictionaryFromJSON:json];
    return [self al_modelSetWithDictionary:dic];
}

- (BOOL)al_modelSetWithDictionary:(NSDictionary *)dic {
    if (!dic || dic == (id) kCFNull) {
        return NO;
    }
    if (![dic isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    
    _ALModelJSONMeta *modelMeta = [_ALModelJSONMeta metaWithClass:object_getClass(self)];
    if (modelMeta->_allPropertyMetas.count == 0) {
        return NO;
    }
    
    if (modelMeta->_hasCustomWillTransformFromDictionary) {
        dic = [((id<YYModel>) self) modelCustomWillTransformFromDictionary:dic];
        if (![dic isKindOfClass:[NSDictionary class]]) {
            return NO;
        }
    }
    
    _ModelSetContext context = {0};
    context.modelMeta = (__bridge void *)(modelMeta);
    context.model = (__bridge void *)(self);
    context.dictionary = (__bridge void *)(dic);
    
    NSInteger keyMappedCount = modelMeta->_allPropertyMetas.count;
    if (keyMappedCount >= CFDictionaryGetCount((CFDictionaryRef)dic)) {
        CFDictionaryApplyFunction((CFDictionaryRef)dic, ModelSetWithDictionaryFunction, &context);
        if (modelMeta->_keyPathPropertyMetas) {
            CFArrayApplyFunction((CFArrayRef)modelMeta->_keyPathPropertyMetas,
                                 CFRangeMake(0, CFArrayGetCount((CFArrayRef)modelMeta->_keyPathPropertyMetas)),
                                 ModelSetWithPropertyMetaArrayFunction,
                                 &context);
        }
        if (modelMeta->_multiKeysPropertyMetas) {
            CFArrayApplyFunction((CFArrayRef)modelMeta->_multiKeysPropertyMetas,
                                 CFRangeMake(0, CFArrayGetCount((CFArrayRef)modelMeta->_multiKeysPropertyMetas)),
                                 ModelSetWithPropertyMetaArrayFunction,
                                 &context);
        }
    } else {
        CFArrayApplyFunction((CFArrayRef)modelMeta->_allPropertyMetas,
                             CFRangeMake(0, modelMeta->_allPropertyMetas.count),
                             ModelSetWithPropertyMetaArrayFunction,
                             &context);
    }
    
    if (modelMeta->_hasCustomTransformFromDictionary) {
        return [((id<YYModel>)self) modelCustomTransformFromDictionary:dic];
    }
    return YES;
}

- (id)al_modelToJSONObject {
    /*
     Apple said:
     The top level object is an NSArray or NSDictionary.
     All objects are instances of NSString, NSNumber, NSArray, NSDictionary, or NSNull.
     All dictionary keys are instances of NSString.
     Numbers are not NaN or infinity.
     */
    id jsonObject = ModelToJSONObjectRecursive(self);
    if ([jsonObject isKindOfClass:[NSArray class]]) {
        return jsonObject;
    }
    if ([jsonObject isKindOfClass:[NSDictionary class]]) {
        return jsonObject;
    }
    return nil;
}

- (NSData *)al_modelToJSONData {
    id jsonObject = [self al_modelToJSONObject];
    if (!jsonObject) {
        return nil;
    }
    return [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:NULL];
}

- (NSString *)al_modelToJSONString {
    NSData *jsonData = [self al_modelToJSONData];
    if (jsonData.length == 0) {
        return nil;
    }
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

@end


