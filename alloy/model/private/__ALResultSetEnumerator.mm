//
//  __ALResultSetEnumerator.m
//  alloy
//
//  Created by Alex Lee on 23/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "__ALResultSetEnumerator.h"
#import "ALUtilitiesHeader.h"
#import "__ALModelMeta+ActiveRecord.h"
#import "__ALPropertyColumnBindings+private.h"
#import <objc/message.h>
#import "NSString+ALHelper.h"
#import "__ALModelHelper.h"

static void _SetModelPropertyValueWithResultSet(__unsafe_unretained id model,
                                                __unsafe_unretained ALDBResultSet *resultSet, int index,
                                                __unsafe_unretained ALPropertyColumnBindings *columnBinding);

@implementation __ALResultSetEnumerator {
    ALDBResultSet *_rs;
    Class _cls;
    std::list<const ALDBResultColumn> _columns;
    
    NSArray<ALPropertyColumnBindings *> *_bindings; // maybe contains NSNull.null
}

+ (NSEnumerator *)enumatorWithResultSet:(ALDBResultSet *)rs
                             modelClass:(Class)cls
                          resultColumns:(const std::list<const ALDBResultColumn>)columns {
    
    __ALResultSetEnumerator *enumator = [[self alloc] init];
    enumator->_rs = rs;
    enumator->_cls = cls;
    enumator->_columns.insert(enumator->_columns.end(), columns.begin(), columns.end());
    return enumator;
}

- (id)nextObject {
    al_guard_or_return(_rs != nil, nil);
    
    if (_cls == nil) {
        return nil;
    }
    
    if (![_rs next]) {
        return nil;
    }
    
    id obj = [[_cls alloc] init];
    int index = 0;
    for (ALPropertyColumnBindings *binding in [self columnBindings]) {
        if ([binding isKindOfClass:ALPropertyColumnBindings.class]) {
            _SetModelPropertyValueWithResultSet(obj, _rs, index, binding);
        }
        index ++;
    }
    return obj;
}

- (NSArray<ALPropertyColumnBindings *> *)columnBindings {
    if (_bindings == nil) {
        NSMutableArray *arr = [NSMutableArray arrayWithCapacity:_columns.size()];

        _ALModelTableBindings *modelBindings = nil;
        auto it = _columns.begin();
        for (int idx = 0; idx < _rs.columnCount; ++idx) {
            ALPropertyColumnBindings *binding = nil;
            NSString *columnName = [_rs columnNameAt:idx];
            if (it != _columns.end()) {
                binding = (*it).column_binding();
                if (binding && ![[binding columnName] isEqualToString:columnName]) {
#if DEBUG
                    if (ALDBColumn::s_any != [binding columnName].UTF8String) {
                        ALLogWarn(@"binding column: %@, but result column is: %@",[binding columnName], columnName);
                    }
#endif
                    binding = nil;
                }
                ++ it;
            }
            if (binding == nil) {
                if (modelBindings == nil) {
                    modelBindings = [_ALModelTableBindings bindingsWithClass:_cls];
                }
                binding = modelBindings->_columnsDict[columnName];
            }
            ALAssert(binding != nil, @"column binding is nil! column:%@", columnName);
            [arr addObject:al_wrapNil(binding)];
        }
        _bindings = [arr copy];
    }
    return _bindings;
}

@end

static AL_FORCE_INLINE void _SetNumberModelPropertyValueWithResultSet(__unsafe_unretained id model,
                                                                      __unsafe_unretained ALDBResultSet *rs, int index,
                                                                      __unsafe_unretained _ALModelPropertyMeta *meta) {
    SEL setter = meta->_setter;
    switch (meta->_type & YYEncodingTypeMask) {
        case YYEncodingTypeBool: {
            ((void (*)(id, SEL, bool))(void *) objc_msgSend)((id) model, setter, [rs boolValueForColumnIndex:index]);
        } break;
        case YYEncodingTypeInt64: {
            ((void (*)(id, SEL, int64_t))(void *) objc_msgSend)((id) model, setter,
                                                                [rs integerValueForColumnIndex:index]);
        } break;
        case YYEncodingTypeUInt64: {
            ((void (*)(id, SEL, uint64_t))(void *) objc_msgSend)((id) model, setter,
                                                                 [rs integerValueForColumnIndex:index]);
        } break;

        case YYEncodingTypeFloat:  // fall
        case YYEncodingTypeDouble: {
            double d = [rs doubleValueForColumnIndex:index];
            if (isnan(d) || isinf(d)) {
                d = 0;
            }
            ((void (*)(id, SEL, double))(void *) objc_msgSend)((id) model, setter, d);
        } break;

        case YYEncodingTypeInt8: {
            ((void (*)(id, SEL, int8_t))(void *) objc_msgSend)((id) model, setter,
                                                               (int8_t) [rs integerValueForColumnIndex:index]);
        } break;
        case YYEncodingTypeUInt8: {
            ((void (*)(id, SEL, uint8_t))(void *) objc_msgSend)((id) model, setter,
                                                                (uint8_t) [rs integerValueForColumnIndex:index]);
        } break;
        case YYEncodingTypeInt16: {
            ((void (*)(id, SEL, int16_t))(void *) objc_msgSend)((id) model, setter,
                                                                (int16_t) [rs integerValueForColumnIndex:index]);
        } break;
        case YYEncodingTypeUInt16: {
            ((void (*)(id, SEL, uint16_t))(void *) objc_msgSend)((id) model, setter,
                                                                 (uint16_t) [rs integerValueForColumnIndex:index]);
        } break;
        case YYEncodingTypeInt32: {
            ((void (*)(id, SEL, int32_t))(void *) objc_msgSend)((id) model, setter,
                                                                (int32_t) [rs integerValueForColumnIndex:index]);
        }
        case YYEncodingTypeUInt32: {
            ((void (*)(id, SEL, uint32_t))(void *) objc_msgSend)((id) model, setter,
                                                                 (uint32_t) [rs integerValueForColumnIndex:index]);
        } break;

        case YYEncodingTypeLongDouble: {
            long double d = [rs doubleValueForColumnIndex:index];
            if (isnan(d) || isinf(d)) {
                d = 0;
            }
            ((void (*)(id, SEL, long double))(void *) objc_msgSend)((id) model, meta->_setter, (long double) d);
        }; break;
        
        default: break;
    }
}

#define __ModelSetPropertyIDValue(model, value, meta)                                          \
    if (meta->_setter == nil) {                                                                \
        _ModelKVCSetValueForProperty(model, value, meta);                                      \
    } else {                                                                                   \
        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter, (id) value); \
    }

static AL_FORCE_INLINE void _SetModelPropertyValueWithResultSet(__unsafe_unretained id model,
                                                         __unsafe_unretained ALDBResultSet *resultSet, int index,
                                                         __unsafe_unretained ALPropertyColumnBindings *columnBinding) {
    
    SEL customSetter = [columnBinding customPropertyValueSetter];
    //SEL: -(void)customSet{PropertyName}WithColumnValue:(id)value
    if (customSetter != nil) {
        ((void (*)(id, SEL, id))(void *)objc_msgSend)((id)model, customSetter, (id)resultSet[index]);
        return;
    }
    
    _ALModelPropertyMeta *meta = columnBinding->_propertyMeta;
    if (meta->_isCNumber) {
        if (meta->_setter == nil) {
            NSNumber *num = _YYNSNumberCreateFromID(resultSet[index]);
            _ModelKVCSetValueForProperty(model, num, meta);
        } else {
            _SetNumberModelPropertyValueWithResultSet(model, resultSet, index, meta);
        }
    } else if (meta->_nsType) {
        switch (meta->_nsType) {
            case YYEncodingTypeNSString: {
                NSString *value = [resultSet stringValueForColumnIndex:index];
                __ModelSetPropertyIDValue(model, value, meta);
            }; break;
                
            case YYEncodingTypeNSMutableString: {
                NSMutableString *value = [[resultSet stringValueForColumnIndex:index] mutableCopy];
                __ModelSetPropertyIDValue(model, value, meta);
            } break;
                
            case YYEncodingTypeNSNumber: {
                id value = _YYNSNumberCreateFromID(resultSet[index]);
                __ModelSetPropertyIDValue(model, value, meta);
            } break;
                
            case YYEncodingTypeNSDecimalNumber: {
                id value = _YYNSNumberCreateFromID(resultSet[index]);
                value = [NSDecimalNumber decimalNumberWithDecimal:[((NSNumber *) value) decimalValue]];
                __ModelSetPropertyIDValue(model, value, meta);
            } break;
                
            case YYEncodingTypeNSValue: {
                @try {
                    NSData *d = [resultSet dataForColumnIndex:index];
                    id value = [NSKeyedUnarchiver unarchiveObjectWithData:d];
                    if ([value isKindOfClass:[NSValue class]]) {
                        __ModelSetPropertyIDValue(model, value, meta);
                    }
                } @catch (NSException *exception) {
                    ALLogWarn(@"extract NSValue from column at :%d, property: %@; exception: %@",
                              index, meta->_name, exception);
                }
            } break;
                
            case YYEncodingTypeNSData: {
                NSData *value = [resultSet dataForColumnIndex:index];
                __ModelSetPropertyIDValue(model, value, meta);
            }; break;
                
            case YYEncodingTypeNSMutableData: {
                NSData *value = [[resultSet dataForColumnIndex:index] mutableCopy];
                __ModelSetPropertyIDValue(model, value, meta);
            } break;
                
            case YYEncodingTypeNSDate: {
                NSDate *value = [resultSet dateForColumnIndex:index];
                __ModelSetPropertyIDValue(model, value, meta);
            } break;
                
            case YYEncodingTypeNSURL: {
                ALDBColumnType ct = [resultSet columnTypeAt:index];
                if (ct == ALDBColumnTypeText) {
                    id value = [resultSet stringValueForColumnIndex:index];
                    value = [NSURL URLWithString:value];
                    __ModelSetPropertyIDValue(model, value, meta);
                    
                } else if (ct == ALDBColumnTypeBlob) {
                    NSData *d = [resultSet dataForColumnIndex:index];
                    @try {
                        id value = [NSKeyedUnarchiver unarchiveObjectWithData:d];
                        if ([value isKindOfClass:[NSURL class]]) {
                            __ModelSetPropertyIDValue(model, value, meta);
                        } else if ([value isKindOfClass:[NSString class]]) {
                            __ModelSetPropertyIDValue(model, [NSURL URLWithString:value], meta);
                        }
                    } @catch (NSException *exception) {
                        ALLogWarn(@"extract NSURL from column at :%d, property: %@; exception: %@",
                                  index, meta->_name, exception);
                    }
                }
            } break;
                
//                case YYEncodingTypeNSArray:
//                case YYEncodingTypeNSMutableArray:
//                case YYEncodingTypeNSDictionary:
//                case YYEncodingTypeNSMutableDictionary:
//                case YYEncodingTypeNSSet:
//                case YYEncodingTypeNSMutableSet:
            default: {
                @try {
                    NSData *d = [resultSet dataForColumnIndex:index];
                    id value = [NSKeyedUnarchiver unarchiveObjectWithData:d];
                    if ([value isKindOfClass:meta->_cls]) {
                        __ModelSetPropertyIDValue(model, value, meta);
                    }
                } @catch (NSException *exception) {
                    ALLogWarn(@"extract %@ from column at :%d, property: %@; exception: %@",
                              meta->_cls, index, meta->_name, exception);
                }
            }; break;
        }
    } else {
        switch (meta->_type & YYEncodingTypeMask) {
            case YYEncodingTypeObject: {
                @try {
                    NSData *d = [resultSet dataForColumnIndex:index];
                    id value = [NSKeyedUnarchiver unarchiveObjectWithData:d];
                    if ([value isKindOfClass:meta->_cls]) {
                        __ModelSetPropertyIDValue(model, value, meta);
                    }
                } @catch (NSException *exception) {
                    ALLogWarn(@"extract %@ from column at :%d, property: %@; exception: %@",
                              meta->_cls, index, meta->_name, exception);
                }
            } break;
                
            case YYEncodingTypeClass: {
                NSString *s = [resultSet stringValueForColumnIndex:index];
                Class value = NSClassFromString(s);
                __ModelSetPropertyIDValue(model, value, meta);
            } break;
                
            case YYEncodingTypeSEL: {
                NSString *s = [resultSet stringValueForColumnIndex:index];
                if (meta->_setter == nil) {
                    _ModelKVCSetValueForProperty(model, s, meta);
                } else {
                    SEL value = NSSelectorFromString(s);
                    ((void (*)(id, SEL, SEL))(void *) objc_msgSend)((id) model, meta->_setter, value);
                }
            } break;
            
//            case YYEncodingTypeStruct:
//            case YYEncodingTypeUnion:
//            case YYEncodingTypeCArray:
            default: {
                @try {
                    NSData *d = [resultSet dataForColumnIndex:index];
                    id value = [NSKeyedUnarchiver unarchiveObjectWithData:d];
                    _ModelKVCSetValueForProperty(model, value, meta);
                } @catch (NSException *exception) {
                    ALLogWarn(@"extract %@ from column at :%d, property: %@; exception: %@",
                              meta->_cls, index, meta->_name, exception);
                }
            }; break;
        }
    }
}
