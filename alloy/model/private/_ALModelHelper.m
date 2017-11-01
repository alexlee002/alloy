//
//  _ALModelHelper.m
//  alloy
//
//  Created by Alex Lee on 06/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "_ALModelHelper.h"
#import "ALMacros.h"
#import <objc/message.h>


AL_FORCE_INLINE BOOL _ALModelKVCSetValueForProperty(__unsafe_unretained id model,
                                                    __unsafe_unretained id value,
                                                    __unsafe_unretained _ALModelPropertyMeta *meta) {
    BOOL result = NO;
    if (meta->_isKVCCompatible) {
        @try {
            if (value) {
                [model setValue:value forKey:meta->_name];
            }
            result = YES;
        } @catch (NSException *e) {}
    }
    return result;
}

/**
 Get number from property.
 @discussion Caller should hold strong reference to the parameters before this function returns.
 @param model Should not be nil.
 @param meta  Should not be nil, meta.isCNumber should be YES, meta.getter should not be nil.
 @return A number object, or nil if failed.
 */
AL_FORCE_INLINE NSNumber *_ALModelCreateNumberFromProperty(__unsafe_unretained id model,
                                                           __unsafe_unretained _ALModelPropertyMeta *meta) {
    switch (meta->_type & YYEncodingTypeMask) {
        case YYEncodingTypeBool: {
            return @(((bool (*)(id, SEL))(void *) objc_msgSend)((id) model, meta->_getter));
        }
        case YYEncodingTypeInt8: {
            return @(((int8_t(*)(id, SEL))(void *) objc_msgSend)((id) model, meta->_getter));
        }
        case YYEncodingTypeUInt8: {
            return @(((uint8_t(*)(id, SEL))(void *) objc_msgSend)((id) model, meta->_getter));
        }
        case YYEncodingTypeInt16: {
            return @(((int16_t(*)(id, SEL))(void *) objc_msgSend)((id) model, meta->_getter));
        }
        case YYEncodingTypeUInt16: {
            return @(((uint16_t(*)(id, SEL))(void *) objc_msgSend)((id) model, meta->_getter));
        }
        case YYEncodingTypeInt32: {
            return @(((int32_t(*)(id, SEL))(void *) objc_msgSend)((id) model, meta->_getter));
        }
        case YYEncodingTypeUInt32: {
            return @(((uint32_t(*)(id, SEL))(void *) objc_msgSend)((id) model, meta->_getter));
        }
        case YYEncodingTypeInt64: {
            return @(((int64_t(*)(id, SEL))(void *) objc_msgSend)((id) model, meta->_getter));
        }
        case YYEncodingTypeUInt64: {
            return @(((uint64_t(*)(id, SEL))(void *) objc_msgSend)((id) model, meta->_getter));
        }
        case YYEncodingTypeFloat: {
            float num = ((float (*)(id, SEL))(void *) objc_msgSend)((id) model, meta->_getter);
            if (isnan(num) || isinf(num)) {
                return nil;
            }
            return @(num);
        }
        case YYEncodingTypeDouble: {
            double num = ((double (*)(id, SEL))(void *) objc_msgSend)((id) model, meta->_getter);
            if (isnan(num) || isinf(num)) {
                return nil;
            }
            return @(num);
        }
        case YYEncodingTypeLongDouble: {
            double num = ((long double (*)(id, SEL))(void *) objc_msgSend)((id) model, meta->_getter);
            if (isnan(num) || isinf(num)) {
                return nil;
            }
            return @(num);
        }
        default:
            return nil;
    }
}


/// Parse a number value from 'id'.
NSNumber *_YYNSNumberCreateFromID(__unsafe_unretained id value) {
    static NSCharacterSet *dot;
    static NSDictionary *dic;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dot = [NSCharacterSet characterSetWithRange:NSMakeRange('.', 1)];
        dic = @{@"TRUE" :   @(YES),
                @"True" :   @(YES),
                @"true" :   @(YES),
                @"FALSE" :  @(NO),
                @"False" :  @(NO),
                @"false" :  @(NO),
                @"YES" :    @(YES),
                @"Yes" :    @(YES),
                @"yes" :    @(YES),
                @"NO" :     @(NO),
                @"No" :     @(NO),
                @"no" :     @(NO),
                @"NIL" :    (id)kCFNull,
                @"Nil" :    (id)kCFNull,
                @"nil" :    (id)kCFNull,
                @"NULL" :   (id)kCFNull,
                @"Null" :   (id)kCFNull,
                @"null" :   (id)kCFNull,
                @"(NULL)" : (id)kCFNull,
                @"(Null)" : (id)kCFNull,
                @"(null)" : (id)kCFNull,
                @"<NULL>" : (id)kCFNull,
                @"<Null>" : (id)kCFNull,
                @"<null>" : (id)kCFNull};
    });
    
    if (!value || value == (id) kCFNull) {
        return nil;
    }
    if ([value isKindOfClass:[NSNumber class]]) {
        return value;
    }
    if ([value isKindOfClass:[NSString class]]) {
        NSNumber *num = dic[value];
        if (num) {
            if (num == (id) kCFNull) {
                return nil;
            }
            return num;
        }
        if ([(NSString *) value rangeOfCharacterFromSet:dot].location != NSNotFound) {
            const char *cstring = ((NSString *) value).UTF8String;
            if (!cstring) {
                return nil;
            }
            
            double num = atof(cstring);
            if (isnan(num) || isinf(num)) {
                return nil;
            }
            return @(num);
        } else {
            const char *cstring = ((NSString *) value).UTF8String;
            if (!cstring) {
                return nil;
            }
            return @(atoll(cstring));
        }
    }
    return nil;
}

/**
 Set number to property.
 @discussion Caller should hold strong reference to the parameters before this function returns.
 @param model Should not be nil.
 @param num   Can be nil.
 @param meta  Should not be nil, meta.isCNumber should be YES, meta.setter should not be nil.
 */
AL_FORCE_INLINE void _ALModelSetNumberToProperty(__unsafe_unretained id model, __unsafe_unretained NSNumber *num,
                                               __unsafe_unretained _ALModelPropertyMeta *meta) {
    switch (meta->_type & YYEncodingTypeMask) {
        case YYEncodingTypeBool: {
            ((void (*)(id, SEL, bool))(void *) objc_msgSend)((id) model, meta->_setter, num.boolValue);
        } break;
        case YYEncodingTypeInt64: {
            if ([num isKindOfClass:[NSDecimalNumber class]]) {
                ((void (*)(id, SEL, int64_t))(void *) objc_msgSend)((id) model, meta->_setter,
                                                                    (int64_t) num.stringValue.longLongValue);
            } else {
                ((void (*)(id, SEL, uint64_t))(void *) objc_msgSend)((id) model, meta->_setter,
                                                                     (uint64_t) num.longLongValue);
            }
        } break;
        case YYEncodingTypeUInt64: {
            if ([num isKindOfClass:[NSDecimalNumber class]]) {
                ((void (*)(id, SEL, int64_t))(void *) objc_msgSend)((id) model, meta->_setter,
                                                                    (int64_t) num.stringValue.longLongValue);
            } else {
                ((void (*)(id, SEL, uint64_t))(void *) objc_msgSend)((id) model, meta->_setter,
                                                                     (uint64_t) num.unsignedLongLongValue);
            }
        } break;
            
        case YYEncodingTypeFloat: {
            float f = num.floatValue;
            if (isnan(f) || isinf(f)) {
                f = 0;
            }
            ((void (*)(id, SEL, float))(void *) objc_msgSend)((id) model, meta->_setter, f);
        } break;
        case YYEncodingTypeDouble: {
            double d = num.doubleValue;
            if (isnan(d) || isinf(d)) {
                d = 0;
            }
            ((void (*)(id, SEL, double))(void *) objc_msgSend)((id) model, meta->_setter, d);
        } break;
            
        case YYEncodingTypeInt8: {
            ((void (*)(id, SEL, int8_t))(void *) objc_msgSend)((id) model, meta->_setter, (int8_t) num.charValue);
        } break;
        case YYEncodingTypeUInt8: {
            ((void (*)(id, SEL, uint8_t))(void *) objc_msgSend)((id) model, meta->_setter,
                                                                (uint8_t) num.unsignedCharValue);
        } break;
        case YYEncodingTypeInt16: {
            ((void (*)(id, SEL, int16_t))(void *) objc_msgSend)((id) model, meta->_setter, (int16_t) num.shortValue);
        } break;
        case YYEncodingTypeUInt16: {
            ((void (*)(id, SEL, uint16_t))(void *) objc_msgSend)((id) model, meta->_setter,
                                                                 (uint16_t) num.unsignedShortValue);
        } break;
        case YYEncodingTypeInt32: {
            ((void (*)(id, SEL, int32_t))(void *) objc_msgSend)((id) model, meta->_setter, (int32_t) num.intValue);
        }
        case YYEncodingTypeUInt32: {
            ((void (*)(id, SEL, uint32_t))(void *) objc_msgSend)((id) model, meta->_setter,
                                                                 (uint32_t) num.unsignedIntValue);
        } break;
            
        case YYEncodingTypeLongDouble: {
            long double d = num.doubleValue;
            if (isnan(d) || isinf(d)) {
                d = 0;
            }
            ((void (*)(id, SEL, long double))(void *) objc_msgSend)((id) model, meta->_setter, (long double) d);
        }  // break; commented for code coverage in next line
        default: {
            //            ALLogError(@"Model \"%@\" can not set value for key:\"%@\"", [model class], meta->_name);
            break;
        }
    }
}

