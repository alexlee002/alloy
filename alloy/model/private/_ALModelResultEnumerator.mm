//
//  _ALModelResultEnumerator.m
//  alloy
//
//  Created by Alex Lee on 09/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "_ALModelResultEnumerator.h"
#import "ALDBColumnBinding_Private.h"
#import "ALDBTableBinding_Private.h"
#import "column.hpp"
#import "ALLogger.h"
#import "ALMacros.h"
#import "NSString+ALHelper.h"
#import "_ALModelMeta.h"
#import "_ALModelHelper.h"
#import <objc/message.h>

static void _SetModelPropertyValueWithResultSet(__unsafe_unretained id model,
                                                __unsafe_unretained ALDBResultSet *resultSet, int index,
                                                __unsafe_unretained ALDBColumnBinding *columnBinding);

@implementation _ALModelResultEnumerator {
    Class _cls;
    ALDBResultSet *_rs;
    NSArray<ALDBColumnBinding *> *_columnBindings;
}

+ (NSEnumerator *)enumeratorWithModel:(Class)cls
                            resultSet:(ALDBResultSet *)resultSet
                        resultColumns:(const ALDBResultColumnList &)columns{
    
    if (resultSet == nil || cls == Nil) {
        return nil;
    }
    _ALModelResultEnumerator *enumator = [[self alloc] init];
    enumator->_rs = resultSet;
    enumator->_cls = cls;
    enumator->_columnBindings = [enumator bindingsWithResultColumn:columns];
    return enumator;
}

- (id)nextObject {
    if (![_rs next]) {
        if ([_rs hasError]) {
            ALLogError(@"%@", [_rs lastError]);
        }
        return nil;
    }
    
    id obj = [[_cls alloc] init];
    int index = 0;
    for (ALDBColumnBinding *binding in _columnBindings) {
        if ([binding isKindOfClass:ALDBColumnBinding.class]) {
            _SetModelPropertyValueWithResultSet(obj, _rs, index, binding);
        }
        index ++;
    }
    return obj;
}

- (NSArray<ALDBColumnBinding *> *)bindingsWithResultColumn:(const ALDBResultColumnList &)columns {
    if (_columnBindings == nil) {
        NSMutableDictionary *resultsBindingsDict = [NSMutableDictionary dictionaryWithCapacity:columns.size()];
        for (auto it : columns) {
            ALDBColumnBinding *columnBinding = it.columnBinding();
            NSString *colname = [columnBinding columnName];
            if (colname) {
                resultsBindingsDict[colname] = columnBinding;
            }
        }
        
        NSMutableArray *arr = [NSMutableArray arrayWithCapacity:columns.size()];
        ALDBTableBinding *modelBindings = nil;
        for (int idx = 0; idx < _rs.columnsCount; ++idx) {
            NSString *columnName = [_rs columnNameAtIndex:idx];
            ALDBColumnBinding *columnBinding = resultsBindingsDict[columnName];
            if (columnBinding == nil) {
                if (modelBindings == nil) {
                    modelBindings = [ALDBTableBinding bindingsWithClass:_cls];
                }
                columnBinding = [modelBindings bindingForColumn:columnName];
            }
            ALAssert(columnBinding != nil, @"column binding is nil! column:%@", columnName);
            [arr addObject:al_wrapNil(columnBinding)];
        }
        _columnBindings = [arr copy];
    }
    return _columnBindings;
}

@end

static AL_FORCE_INLINE void _SetNumberModelPropertyValueWithResultSet(__unsafe_unretained id model,
                                                                      __unsafe_unretained ALDBResultSet *rs, int index,
                                                                      __unsafe_unretained _ALModelPropertyMeta *meta) {
    SEL setter = meta->_setter;
    switch (meta->_type & YYEncodingTypeMask) {
        case YYEncodingTypeBool: {
            ((void (*)(id, SEL, bool))(void *) objc_msgSend)((id) model, setter, [rs boolForColumnIndex:index]);
        } break;
        case YYEncodingTypeInt64: {
            ((void (*)(id, SEL, int64_t))(void *) objc_msgSend)((id) model, setter,
                                                                [rs integerForColumnIndex:index]);
        } break;
        case YYEncodingTypeUInt64: {
            ((void (*)(id, SEL, uint64_t))(void *) objc_msgSend)((id) model, setter,
                                                                 [rs integerForColumnIndex:index]);
        } break;

        case YYEncodingTypeFloat:  // fall
        case YYEncodingTypeDouble: {
            double d = [rs doubleForColumnIndex:index];
            if (isnan(d) || isinf(d)) {
                d = 0;
            }
            ((void (*)(id, SEL, double))(void *) objc_msgSend)((id) model, setter, d);
        } break;

        case YYEncodingTypeInt8: {
            ((void (*)(id, SEL, int8_t))(void *) objc_msgSend)((id) model, setter,
                                                               (int8_t) [rs integerForColumnIndex:index]);
        } break;
        case YYEncodingTypeUInt8: {
            ((void (*)(id, SEL, uint8_t))(void *) objc_msgSend)((id) model, setter,
                                                                (uint8_t) [rs integerForColumnIndex:index]);
        } break;
        case YYEncodingTypeInt16: {
            ((void (*)(id, SEL, int16_t))(void *) objc_msgSend)((id) model, setter,
                                                                (int16_t) [rs integerForColumnIndex:index]);
        } break;
        case YYEncodingTypeUInt16: {
            ((void (*)(id, SEL, uint16_t))(void *) objc_msgSend)((id) model, setter,
                                                                 (uint16_t) [rs integerForColumnIndex:index]);
        } break;
        case YYEncodingTypeInt32: {
            ((void (*)(id, SEL, int32_t))(void *) objc_msgSend)((id) model, setter,
                                                                (int32_t) [rs integerForColumnIndex:index]);
        }
        case YYEncodingTypeUInt32: {
            ((void (*)(id, SEL, uint32_t))(void *) objc_msgSend)((id) model, setter,
                                                                 (uint32_t) [rs integerForColumnIndex:index]);
        } break;

        case YYEncodingTypeLongDouble: {
            long double d = [rs doubleForColumnIndex:index];
            if (isnan(d) || isinf(d)) {
                d = 0;
            }
            ((void (*)(id, SEL, long double))(void *) objc_msgSend)((id) model, meta->_setter, (long double) d);
        }; break;

        default:
            break;
    }
}

#define __ModelSetPropertyIDValue(model, value, meta)                                          \
    if (meta->_setter == nil) {                                                                \
        _ALModelKVCSetValueForProperty(model, value, meta);                                    \
    } else {                                                                                   \
        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter, (id) value); \
    }

static AL_FORCE_INLINE void _SetModelPropertyValueWithResultSet(__unsafe_unretained id model,
                                                                __unsafe_unretained ALDBResultSet *resultSet, int index,
                                                                __unsafe_unretained ALDBColumnBinding *columnBinding) {
    SEL customSetter = [columnBinding customPropertyValueSetter];
    // SEL: -(void)customSet{PropertyName}WithColumnValue:(id)value
    if (customSetter != nil) {
        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, customSetter, (id) resultSet[index]);
        return;
    }

    _ALModelPropertyMeta *meta = columnBinding->_propertyMeta;
    if (meta->_isCNumber) {
        if (meta->_setter == nil) {
            NSNumber *num = _YYNSNumberCreateFromID(resultSet[index]);
            _ALModelKVCSetValueForProperty(model, num, meta);
        } else {
            _SetNumberModelPropertyValueWithResultSet(model, resultSet, index, meta);
        }
    } else if (meta->_NSType) {
        switch (meta->_NSType) {
            case YYEncodingTypeNSString: {
                NSString *value = [resultSet stringForColumnIndex:index];
                __ModelSetPropertyIDValue(model, value, meta);
            }; break;

            case YYEncodingTypeNSMutableString: {
                NSMutableString *value = [[resultSet stringForColumnIndex:index] mutableCopy];
                __ModelSetPropertyIDValue(model, value, meta);
            } break;

            case YYEncodingTypeNSNumber: {
                id value = _YYNSNumberCreateFromID(resultSet[index]);
                __ModelSetPropertyIDValue(model, value, meta);
            } break;

            case YYEncodingTypeNSDecimalNumber: {
                id value = _YYNSNumberCreateFromID(resultSet[index]);
                value    = [NSDecimalNumber decimalNumberWithDecimal:[((NSNumber *) value) decimalValue]];
                __ModelSetPropertyIDValue(model, value, meta);
            } break;

            case YYEncodingTypeNSValue: {
                @try {
                    NSData *d = [resultSet dataForColumnIndex:index];
                    id value  = [NSKeyedUnarchiver unarchiveObjectWithData:d];
                    if ([value isKindOfClass:[NSValue class]]) {
                        __ModelSetPropertyIDValue(model, value, meta);
                    }
                } @catch (NSException *exception) {
                    ALLogWarn(@"extract NSValue from column at :%d, property: %@; exception: %@", index, meta->_name,
                              exception);
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
                ALDBColumnType ct = [resultSet columnTypeAtIndex:index];
                if (ct == ALDBColumnTypeText) {
                    id value = [resultSet stringForColumnIndex:index];
                    value    = [NSURL URLWithString:value];
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
                        NSString *value = [[NSString alloc]initWithData:d encoding:NSUTF8StringEncoding];
                        __ModelSetPropertyIDValue(model, [NSURL URLWithString:value], meta);
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
                    id value  = [NSKeyedUnarchiver unarchiveObjectWithData:d];
                    if ([value isKindOfClass:meta->_cls]) {
                        __ModelSetPropertyIDValue(model, value, meta);
                    }
                } @catch (NSException *exception) {
                    ALLogWarn(@"extract %@ from column at :%d, property: %@; exception: %@", meta->_cls, index,
                              meta->_name, exception);
                }
            }; break;
        }
    } else {
        switch (meta->_type & YYEncodingTypeMask) {
            case YYEncodingTypeObject: {
                @try {
                    NSData *d = [resultSet dataForColumnIndex:index];
                    id value  = [NSKeyedUnarchiver unarchiveObjectWithData:d];
                    if ([value isKindOfClass:meta->_cls]) {
                        __ModelSetPropertyIDValue(model, value, meta);
                    }
                } @catch (NSException *exception) {
                    ALLogWarn(@"extract %@ from column at :%d, property: %@; exception: %@", meta->_cls, index,
                              meta->_name, exception);
                }
            } break;

            case YYEncodingTypeClass: {
                NSString *s = [resultSet stringForColumnIndex:index];
                Class value = NSClassFromString(s);
                __ModelSetPropertyIDValue(model, value, meta);
            } break;

            case YYEncodingTypeSEL: {
                NSString *s = [resultSet stringForColumnIndex:index];
                if (meta->_setter == nil) {
                    _ALModelKVCSetValueForProperty(model, s, meta);
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
                    id value  = [NSKeyedUnarchiver unarchiveObjectWithData:d];
                    _ALModelKVCSetValueForProperty(model, value, meta);
                } @catch (NSException *exception) {
                    ALLogWarn(@"extract %@ from column at :%d, property: %@; exception: %@", meta->_cls, index,
                              meta->_name, exception);
                }
            }; break;
        }
    }
}
