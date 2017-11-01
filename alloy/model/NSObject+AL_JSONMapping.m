//
//  NSObject+AL_JSONMapping.m
//  alloy
//
//  Created by Alex Lee on 06/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "NSObject+AL_JSONMapping.h"
#import "ALMacros.h"
#import "_ALModelMetaJSONMapping.h"
#import "YYModel.h"
#import "_ALModelHelper.h"
#import "NSDate+ALExtensions.h"
#import "ALLogger.h"
#import <objc/message.h>

/// Get the 'NSBlock' class.
static AL_FORCE_INLINE Class _YYNSBlockClass() {
    static Class cls;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        void (^block)(void) = ^{};
        cls = ((NSObject *) block).class;
        while (class_getSuperclass(cls) != [NSObject class]) {
            cls = class_getSuperclass(cls);
        }
    });
    return cls;  // current is "NSBlock"
}

/**
 Get the ISO date formatter.
 
 ISO8601 format example:
 2010-07-09T16:13:30+12:00
 2011-01-11T11:11:11+0000
 2011-01-26T19:06:43Z
 
 length: 20/24/25
 */
static AL_FORCE_INLINE NSDateFormatter *_YYISODateFormatter() {
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
    });
    return formatter;
}

/// Get the value with key paths from dictionary
/// The dic should be NSDictionary, and the keyPath should not be nil.
static AL_FORCE_INLINE id _YYValueForKeyPath(__unsafe_unretained NSDictionary *dic,
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
static AL_FORCE_INLINE id _YYValueForMultiKeys(__unsafe_unretained NSDictionary *dic,
                                               __unsafe_unretained NSArray *multiKeys) {
    id value = nil;
    for (NSString *key in multiKeys) {
        if ([key isKindOfClass:[NSString class]]) {
            value = dic[key];
            if (value) break;
        } else {
            value = _YYValueForKeyPath(dic, (NSArray *)key);
            if (value) break;
        }
    }
    return value;
}

/**
 Set value to model with a property meta.
 
 @discussion Caller should hold strong reference to the parameters before this function returns.
 
 @param model Should not be nil.
 @param value Should not be nil, but can be NSNull.
 @param meta  Should not be nil, and meta->_setter should not be nil.
 */
static AL_FORCE_INLINE void _ModelSetValueForProperty(__unsafe_unretained id model,
                                                      __unsafe_unretained id value,
                                                      __unsafe_unretained _ALModelPropertyMeta *meta,
                                                      __unsafe_unretained Class _Nullable genericClass,
                                                      SEL _Nullable customClassForDictionarySelector) {
    
    if (meta->_setter == nil) {
        _ALModelKVCSetValueForProperty(model, value, meta);
        return;
    }
    
    if (meta->_isCNumber) {
        NSNumber *num = _YYNSNumberCreateFromID(value);
        _ALModelSetNumberToProperty(model, num, meta);
        if (num) {  // hold the number
            [num class];
        }
    } else if (meta->_NSType) {
        if (value == (id) kCFNull) {
            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter, (id) nil);
        } else {
            switch (meta->_NSType) {
                case YYEncodingTypeNSString:
                case YYEncodingTypeNSMutableString: {
                    if ([value isKindOfClass:[NSString class]]) {
                        if (meta->_NSType == YYEncodingTypeNSString) {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter, value);
                        } else {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter,
                                                                           ((NSString *) value).mutableCopy);
                        }
                    } else if ([value isKindOfClass:[NSNumber class]]) {
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)(
                                                                       (id) model, meta->_setter, (meta->_NSType == YYEncodingTypeNSString)
                                                                       ? ((NSNumber *) value).stringValue
                                                                       : ((NSNumber *) value).stringValue.mutableCopy);
                    } else if ([value isKindOfClass:[NSData class]]) {
                        NSMutableString *string =
                        [[NSMutableString alloc] initWithData:value encoding:NSUTF8StringEncoding];
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter, string);
                    } else if ([value isKindOfClass:[NSURL class]]) {
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)(
                                                                       (id) model, meta->_setter, (meta->_NSType == YYEncodingTypeNSString)
                                                                       ? ((NSURL *) value).absoluteString
                                                                       : ((NSURL *) value).absoluteString.mutableCopy);
                    } else if ([value isKindOfClass:[NSAttributedString class]]) {
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)(
                                                                       (id) model, meta->_setter, (meta->_NSType == YYEncodingTypeNSString)
                                                                       ? ((NSAttributedString *) value).string
                                                                       : ((NSAttributedString *) value).string.mutableCopy);
                    }
                } break;
                    
                case YYEncodingTypeNSNumber: {
                    ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter,
                                                                   _YYNSNumberCreateFromID(value));
                } break;
                case YYEncodingTypeNSDecimalNumber: {
                    if ([value isKindOfClass:[NSDecimalNumber class]]) {
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter, value);
                    } else if ([value isKindOfClass:[NSNumber class]]) {
                        NSDecimalNumber *decNum =
                        [NSDecimalNumber decimalNumberWithDecimal:[((NSNumber *) value) decimalValue]];
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter, decNum);
                    } else if ([value isKindOfClass:[NSString class]]) {
                        NSDecimalNumber *decNum = [NSDecimalNumber decimalNumberWithString:value];
                        NSDecimal dec           = decNum.decimalValue;
                        if (dec._length == 0 && dec._isNegative) {
                            decNum = nil;  // NaN
                        }
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter, decNum);
                    }
                } break;
                case YYEncodingTypeNSValue: {
                    if ([value isKindOfClass:[NSValue class]]) {
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter, value);
                    }
                } break;
                    
                case YYEncodingTypeNSData:
                case YYEncodingTypeNSMutableData: {
                    if ([value isKindOfClass:[NSData class]]) {
                        if (meta->_NSType == YYEncodingTypeNSData) {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter, value);
                        } else {
                            NSMutableData *data = ((NSData *) value).mutableCopy;
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter, data);
                        }
                    } else if ([value isKindOfClass:[NSString class]]) {
                        NSData *data = [(NSString *) value dataUsingEncoding:NSUTF8StringEncoding];
                        if (meta->_NSType == YYEncodingTypeNSMutableData) {
                            data = ((NSData *) data).mutableCopy;
                        }
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter, data);
                    }
                } break;
                    
                case YYEncodingTypeNSDate: {
                    if ([value isKindOfClass:[NSDate class]]) {
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter, value);
                    } else if ([value isKindOfClass:[NSString class]]) {
                        NSDate *d = [NSDate al_dateFromFormattedString:value];
                        if (d == nil) {
                            CFTimeInterval t = [value doubleValue];
                            d = [NSDate dateWithTimeIntervalSince1970:t];
                        }
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter, d);
                    } else if ([value isKindOfClass:[NSNumber class]]) {
                        CFTimeInterval t = [value doubleValue];
                        NSDate *d = [NSDate dateWithTimeIntervalSince1970:t];
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter, d);
                    }
                } break;
                    
                case YYEncodingTypeNSURL: {
                    if ([value isKindOfClass:[NSURL class]]) {
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter, value);
                    } else if ([value isKindOfClass:[NSString class]]) {
                        NSCharacterSet *set = [NSCharacterSet whitespaceAndNewlineCharacterSet];
                        NSString *str       = [value stringByTrimmingCharactersInSet:set];
                        if (str.length == 0) {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter, nil);
                        } else {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter,
                                                                           [[NSURL alloc] initWithString:str]);
                        }
                    }
                } break;
                    
                case YYEncodingTypeNSArray:
                case YYEncodingTypeNSMutableArray: {
                    if (genericClass) {
                        NSArray *valueArr = nil;
                        if ([value isKindOfClass:[NSArray class]]) {
                            valueArr = value;
                        } else if ([value isKindOfClass:[NSSet class]]) {
                            valueArr = ((NSSet *) value).allObjects;
                        }
                        if (valueArr) {
                            NSMutableArray *objectArr = [NSMutableArray new];
                            for (id one in valueArr) {
                                if ([one isKindOfClass:genericClass]) {
                                    [objectArr addObject:one];
                                } else if ([one isKindOfClass:[NSDictionary class]]) {
                                    Class cls = genericClass;
                                    if (customClassForDictionarySelector) {
                                        cls = (Class)((id(*)(id, SEL, id))(void *) objc_msgSend)(
                                                                                                 (id) cls, customClassForDictionarySelector, one);
                                        // for xcode code coverage
                                        if (!cls || !class_isMetaClass(cls)) {
                                            cls = genericClass;
                                        }
                                    }
                                    NSObject *newOne = [[cls alloc] init];
                                    [newOne al_modelSetWithDictionary:one];
                                    if (newOne) {
                                        [objectArr addObject:newOne];
                                    }
                                }
                            }
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter, objectArr);
                        }
                    } else {
                        if ([value isKindOfClass:[NSArray class]]) {
                            if (meta->_NSType == YYEncodingTypeNSArray) {
                                ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter, value);
                            } else {
                                ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter,
                                                                               ((NSArray *) value).mutableCopy);
                            }
                        } else if ([value isKindOfClass:[NSSet class]]) {
                            if (meta->_NSType == YYEncodingTypeNSArray) {
                                ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter,
                                                                               ((NSSet *) value).allObjects);
                            } else {
                                ((void (*)(id, SEL, id))(void *) objc_msgSend)(
                                                                               (id) model, meta->_setter, ((NSSet *) value).allObjects.mutableCopy);
                            }
                        }
                    }
                } break;
                    
                case YYEncodingTypeNSDictionary:
                case YYEncodingTypeNSMutableDictionary: {
                    if ([value isKindOfClass:[NSDictionary class]]) {
                        if (genericClass) {
                            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
                            [((NSDictionary *) value) enumerateKeysAndObjectsUsingBlock:^(NSString *oneKey, id oneValue,
                                                                                          BOOL *stop) {
                                if ([oneValue isKindOfClass:[NSDictionary class]]) {
                                    Class cls = genericClass;
                                    if (customClassForDictionarySelector) {
                                        cls = (Class)((id(*)(id, SEL, id))(void *) objc_msgSend)(
                                                                                                 (id) cls, customClassForDictionarySelector, oneValue);
                                        // for xcode code coverage
                                        if (!cls || !class_isMetaClass(cls)) {
                                            cls = genericClass;
                                        }
                                    }
                                    NSObject *newOne = [[cls alloc] init];
                                    [newOne al_modelSetWithDictionary:(id) oneValue];
                                    if (newOne) {
                                        dic[oneKey] = newOne;
                                    }
                                }
                            }];
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter, dic);
                        } else {
                            if (meta->_NSType == YYEncodingTypeNSDictionary) {
                                ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter, value);
                            } else {
                                ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter,
                                                                               ((NSDictionary *) value).mutableCopy);
                            }
                        }
                    }
                } break;
                    
                case YYEncodingTypeNSSet:
                case YYEncodingTypeNSMutableSet: {
                    NSSet *valueSet = nil;
                    if ([value isKindOfClass:[NSArray class]]) {
                        valueSet = [NSMutableSet setWithArray:value];
                    } else if ([value isKindOfClass:[NSSet class]]) {
                        valueSet = ((NSSet *) value);
                    }
                    
                    if (genericClass) {
                        NSMutableSet *set = [NSMutableSet set];
                        for (id one in valueSet) {
                            if ([one isKindOfClass:genericClass]) {
                                [set addObject:one];
                            } else if ([one isKindOfClass:[NSDictionary class]]) {
                                Class cls = genericClass;
                                if (customClassForDictionarySelector) {
                                    cls = (Class)((id(*)(id, SEL, id))(void *) objc_msgSend)(
                                                                                             (id) cls, customClassForDictionarySelector, one);
                                    // for xcode code coverage
                                    if (!cls || !class_isMetaClass(cls)) {
                                        cls = genericClass;
                                    }
                                }
                                NSObject *newOne = [[cls alloc] init];
                                [newOne al_modelSetWithDictionary:one];
                                if (newOne) {
                                    [set addObject:newOne];
                                }
                            }
                        }
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter, set);
                    } else {
                        if (meta->_NSType == YYEncodingTypeNSSet) {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter, valueSet);
                        } else {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter,
                                                                           ((NSSet *) valueSet).mutableCopy);
                        }
                    }
                }  // break; commented for code coverage in next line
                    
                default:
                    break;
            }
        }
    } else {
        BOOL isNull = (value == (id) kCFNull);
        switch (meta->_type & YYEncodingTypeMask) {
            case YYEncodingTypeObject: {
                if (isNull) {
                    ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter, (id) nil);
                } else if ([value isKindOfClass:meta->_cls] || !meta->_cls) {
                    ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter, (id) value);
                } else if ([value isKindOfClass:[NSDictionary class]]) {
                    NSObject *one = nil;
                    if (meta->_getter) {
                        one = ((id(*)(id, SEL))(void *) objc_msgSend)((id) model, meta->_getter);
                    }
                    if (one) {
                        [one al_modelSetWithDictionary:value];
                    } else {
                        Class cls = meta->_cls;
                        if (customClassForDictionarySelector) {
                            cls = (Class)((id(*)(id, SEL, id))(void *) objc_msgSend)(
                                                                                     (id) cls, customClassForDictionarySelector, value);
                            // for xcode code coverage
                            if (!cls || !class_isMetaClass(cls)) {
                                cls = genericClass;
                            }
                        }
                        one = [[cls alloc] init];
                        [one al_modelSetWithDictionary:value];
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter, (id) one);
                    }
                }
            } break;
                
            case YYEncodingTypeClass: {
                if (isNull) {
                    ((void (*)(id, SEL, Class))(void *) objc_msgSend)((id) model, meta->_setter, (Class) NULL);
                } else {
                    Class cls = nil;
                    if ([value isKindOfClass:[NSString class]]) {
                        cls = NSClassFromString(value);
                        if (cls) {
                            ((void (*)(id, SEL, Class))(void *) objc_msgSend)((id) model, meta->_setter, (Class) cls);
                        }
                    } else {
                        cls = object_getClass(value);
                        if (cls && class_isMetaClass(cls)) {
                            ((void (*)(id, SEL, Class))(void *) objc_msgSend)((id) model, meta->_setter, (Class) value);
                        }
                    }
                }
            } break;
                
            case YYEncodingTypeSEL: {
                if (isNull) {
                    ((void (*)(id, SEL, SEL))(void *) objc_msgSend)((id) model, meta->_setter, (SEL) NULL);
                } else if ([value isKindOfClass:[NSString class]]) {
                    SEL sel = NSSelectorFromString(value);
                    if (sel) {
                        ((void (*)(id, SEL, SEL))(void *) objc_msgSend)((id) model, meta->_setter, (SEL) sel);
                    }
                }
            } break;
                
            case YYEncodingTypeBlock: {
                if (isNull) {
                    ((void (*)(id, SEL, void (^)(void)))(void *) objc_msgSend)((id) model, meta->_setter,
                                                                               (void (^)(void)) NULL);
                } else if ([value isKindOfClass:_YYNSBlockClass()]) {
                    ((void (*)(id, SEL, void (^)(void)))(void *) objc_msgSend)((id) model, meta->_setter,
                                                                               (void (^)(void)) value);
                }
            } break;
                
            case YYEncodingTypeStruct:
            case YYEncodingTypeUnion:
            case YYEncodingTypeCArray: {
                if ([value isKindOfClass:[NSValue class]]) {
                    const char *valueType = ((NSValue *) value).objCType;
                    const char *metaType  = meta->_info.typeEncoding.UTF8String;
                    if (valueType && metaType && strcmp(valueType, metaType) == 0) {
                        [model setValue:value forKey:meta->_name];
                    }
                }
            } break;
                
            case YYEncodingTypePointer:
            case YYEncodingTypeCString: {
                if (isNull) {
                    ((void (*)(id, SEL, void *))(void *) objc_msgSend)((id) model, meta->_setter, (void *) NULL);
                } else if ([value isKindOfClass:[NSValue class]]) {
                    NSValue *nsValue = value;
                    if (nsValue.objCType && strcmp(nsValue.objCType, "^v") == 0) {
                        ((void (*)(id, SEL, void *))(void *) objc_msgSend)((id) model, meta->_setter,
                                                                           nsValue.pointerValue);
                    }
                }
            }  // break; commented for code coverage in next line

            default: {
                ALLogError(@"Model \"<%@: %p>\" can not set value for property:\"%@\"", [model class], model,
                           meta->_name);
                break;
            }
        }
    }
}

typedef struct {
    void *modelMeta;  ///< _ALModelJSONMapping
    void *model;      ///< id (self)
    void *dictionary; ///< NSDictionary (json)
} _ModelSetContext;

/**
 Apply function for dictionary, to set the key-value pair to model.
 
 @param _key     should not be nil, NSString.
 @param _value   should not be nil.
 @param _context _context.modelMeta and _context.model should not be nil.
 */
static AL_FORCE_INLINE void ModelSetWithDictionaryFunction(const void *_key, const void *_value, void *_context) {
    _ModelSetContext *context = _context;
    __unsafe_unretained _ALModelJSONMapping *meta = (__bridge _ALModelJSONMapping *)(context->modelMeta);
    __unsafe_unretained _ALModelPropertyJSONMapping *propertyMeta = [meta->_mapper objectForKey:(__bridge id)(_key)];
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
static AL_FORCE_INLINE void ModelSetWithPropertyMetaArrayFunction(const void *_propertyMeta, void *_context) {
    _ModelSetContext *context = _context;
    __unsafe_unretained NSDictionary *dictionary = (__bridge NSDictionary *) (context->dictionary);
    __unsafe_unretained _ALModelPropertyJSONMapping *propertyMeta =
        (__bridge _ALModelPropertyJSONMapping *) (_propertyMeta);

    id value = nil;

    if (propertyMeta->_mappedToKeyArray) {
        value = _YYValueForMultiKeys(dictionary, propertyMeta->_mappedToKeyArray);
    } else if (propertyMeta->_mappedToKeyPath) {
        value = _YYValueForKeyPath(dictionary, propertyMeta->_mappedToKeyPath);
    } else {
        value = [dictionary objectForKey:propertyMeta->_mappedToKey];
    }

    if (value) {
        __unsafe_unretained id model = (__bridge id)(context->model);
        _ModelSetValueForProperty(
            model, value, propertyMeta->_meta, propertyMeta->_genericClass,
            propertyMeta->_hasCustomClassFromDictionary ? @selector(modelCustomClassForDictionary:) : nil);
    }
}

static id ModelToJSONObjectRecursive(NSObject *model);
static AL_FORCE_INLINE NSArray *ModelToJSONObjectWithArray(NSArray *array) {
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
static AL_FORCE_INLINE id ModelToJSONObjectRecursive(NSObject *model) {
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
    
    _ALModelJSONMapping *modelMeta = [_ALModelJSONMapping mappingWithClass:[model class]];
    if (!modelMeta || modelMeta->_allPropertyMetas.count == 0) {
        return nil;
    }
    
    NSMutableDictionary *result                  = [[NSMutableDictionary alloc] initWithCapacity:64];
    __unsafe_unretained NSMutableDictionary *dic = result;  // avoid retain and release in block
    [modelMeta->_mapper enumerateKeysAndObjectsUsingBlock:^(NSString *propertyMappedKey,
                                                            _ALModelPropertyJSONMapping *jsonPropMeta,
                                                            BOOL *stop) {
        _ALModelPropertyMeta *propMeta = jsonPropMeta->_meta;
        if (!propMeta || !propMeta->_getter) {
            return;
        }
        
        id value = nil;
        if (propMeta->_isCNumber) {
            value = _ALModelCreateNumberFromProperty(model, propMeta);
        } else if (propMeta->_NSType) {
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
    NSDictionary *dict = [self dictionaryFromJSON:JSON];
    return [self al_modelWithDictionary:dict];
}

+ (instancetype)al_modelWithDictionary:(NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    Class cls = [self class];
    _ALModelJSONMapping *modelMapping = [_ALModelJSONMapping mappingWithClass:cls];
    if (modelMapping->_hasCustomClassFromDictionary) {
        cls = [cls modelCustomClassForDictionary:dictionary] ?: cls;
    }
    
    NSObject *one = [[cls alloc] init];
    if ([one al_modelSetWithDictionary:dictionary]) {
        return one;
    }
    return nil;
}

+ (NSDictionary *)dictionaryFromJSON:(id)json {
    if (!json || json == (id) kCFNull) {
        return nil;
    }
    
    NSDictionary *dic = nil;
    if ([json isKindOfClass:[NSDictionary class]]) {
        dic = json;
    } else {
        NSData *jsonData = nil;
        if ([json isKindOfClass:[NSString class]]) {
            jsonData = [(NSString *) json dataUsingEncoding:NSUTF8StringEncoding];
        } else if ([json isKindOfClass:[NSData class]]) {
            jsonData = json;
        }
        if (jsonData) {
            dic = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:NULL];
            if (![dic isKindOfClass:[NSDictionary class]]) {
                dic = nil;
            }
        }
    }
    return dic;
}

- (BOOL)al_modelSetWithJSON:(id)json {
    NSDictionary *dic = [self.class dictionaryFromJSON:json];
    return [self al_modelSetWithDictionary:dic];
}

- (BOOL)al_modelSetWithDictionary:(NSDictionary *)dic {
    if (!dic || dic == (id) kCFNull) {
        return NO;
    }
    if (![dic isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    
    _ALModelJSONMapping *modelMapping = [_ALModelJSONMapping mappingWithClass:object_getClass(self)];
    if (modelMapping->_allPropertyMetas.count == 0) {
        return NO;
    }
    
    if (modelMapping->_hasCustomWillTransformFromDictionary) {
        dic = [((id<YYModel>) self) modelCustomWillTransformFromDictionary:dic];
        if (![dic isKindOfClass:[NSDictionary class]]) {
            return NO;
        }
    }

    _ModelSetContext context = {0};
    context.modelMeta        = (__bridge void *) (modelMapping);
    context.model            = (__bridge void *) (self);
    context.dictionary       = (__bridge void *) (dic);

    NSInteger keyMappedCount = modelMapping->_allPropertyMetas.count;
    if (keyMappedCount >= CFDictionaryGetCount((CFDictionaryRef)dic)) {
        CFDictionaryApplyFunction((CFDictionaryRef)dic, ModelSetWithDictionaryFunction, &context);
        if (modelMapping->_keyPathPropertyMetas) {
            CFArrayApplyFunction((CFArrayRef)modelMapping->_keyPathPropertyMetas,
                                 CFRangeMake(0, CFArrayGetCount((CFArrayRef)modelMapping->_keyPathPropertyMetas)),
                                 ModelSetWithPropertyMetaArrayFunction,
                                 &context);
        }
        if (modelMapping->_multiKeysPropertyMetas) {
            CFArrayApplyFunction((CFArrayRef)modelMapping->_multiKeysPropertyMetas,
                                 CFRangeMake(0, CFArrayGetCount((CFArrayRef)modelMapping->_multiKeysPropertyMetas)),
                                 ModelSetWithPropertyMetaArrayFunction,
                                 &context);
        }
    } else {
        CFArrayApplyFunction((CFArrayRef)modelMapping->_allPropertyMetas,
                             CFRangeMake(0, modelMapping->_allPropertyMetas.count),
                             ModelSetWithPropertyMetaArrayFunction,
                             &context);
    }
    
    if (modelMapping->_hasCustomTransformFromDictionary) {
        return [((id<YYModel>)self) modelCustomTransformFromDictionary:dic];
    }
    return YES;
}

+ (nullable NSArray *)al_modelArrayWithJSON:(id)json {
    return [NSArray al_modelArrayWithClass:self JSON:json];
}

+ (nullable NSDictionary *)al_modelDictionaryWithJSON:(id)json {
    return [NSDictionary al_modelDictionaryWithClass:self JSON:json];
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


@implementation NSArray (AL_JSONMapping)

+ (NSArray *)al_modelArrayWithClass:(Class)cls JSON:(id)json {
    if (!json) {
        return nil;
    }
    NSArray *arr     = nil;
    NSData *jsonData = nil;
    if ([json isKindOfClass:[NSArray class]]) {
        arr = json;
        
    } else if ([json isKindOfClass:[NSString class]]) {
        jsonData = [(NSString *) json dataUsingEncoding:NSUTF8StringEncoding];
        
    } else if ([json isKindOfClass:[NSData class]]) {
        jsonData = json;
    }
    if (jsonData) {
        arr = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:NULL];
        if (![arr isKindOfClass:[NSArray class]]) {
            arr = nil;
        }
    }
    return [self al_modelArrayWithClass:cls array:arr];
}

+ (NSArray *)al_modelArrayWithClass:(Class)cls array:(NSArray *)arr {
    if (!cls || !arr) {
        return nil;
    }
    NSMutableArray *result = [NSMutableArray array];
    for (NSDictionary *dic in arr) {
        if (![dic isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        NSObject *obj = [cls al_modelWithDictionary:dic];
        if (obj) {
            [result addObject:obj];
        }
    }
    return result;
}

@end


@implementation NSDictionary (AL_JSONMapping)

+ (NSDictionary *)al_modelDictionaryWithClass:(Class)cls JSON:(id)json {
    if (!json) {
        return nil;
    }
    NSDictionary *dic = nil;
    NSData *jsonData  = nil;
    if ([json isKindOfClass:[NSDictionary class]]) {
        dic = json;
    } else if ([json isKindOfClass:[NSString class]]) {
        jsonData = [(NSString *) json dataUsingEncoding:NSUTF8StringEncoding];
    } else if ([json isKindOfClass:[NSData class]]) {
        jsonData = json;
    }
    if (jsonData) {
        dic = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:NULL];
        if (![dic isKindOfClass:[NSDictionary class]]) {
            dic = nil;
        }
    }
    return [self al_modelDictionaryWithClass:cls dictionary:dic];
}

+ (NSDictionary *)al_modelDictionaryWithClass:(Class)cls dictionary:(NSDictionary *)dic {
    if (!cls || !dic) {
        return nil;
    }
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    for (NSString *key in dic.allKeys) {
        if (![key isKindOfClass:[NSString class]]) {
            continue;
        }
        NSObject *obj = [cls al_modelWithDictionary:dic[key]];
        if (obj) {
            result[key] = obj;
        }
    }
    return result;
}

@end
