//
//  __ALModelHelper.m
//  patchwork
//
//  Created by Alex Lee on 09/06/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "__ALModelHelper.h"
#import "ALUtilitiesHeader.h"
#import "__ALModelMeta.h"
#import <objc/message.h>
#import "NSObject+AL_JSONMapping.h"

NSString *const _ALNSUnknownKeyException = @"NSUnknownKeyException";

/// Get the Foundation class type from property info.
AL_FORCE_INLINE _YYEncodingNSType _YYClassGetNSType(Class cls) {
    if (!cls) return YYEncodingTypeNSUnknown;
    if ([cls isSubclassOfClass:[NSMutableString class]])     return YYEncodingTypeNSMutableString;
    if ([cls isSubclassOfClass:[NSString class]])            return YYEncodingTypeNSString;
    if ([cls isSubclassOfClass:[NSDecimalNumber class]])     return YYEncodingTypeNSDecimalNumber;
    if ([cls isSubclassOfClass:[NSNumber class]])            return YYEncodingTypeNSNumber;
    if ([cls isSubclassOfClass:[NSValue class]])             return YYEncodingTypeNSValue;
    if ([cls isSubclassOfClass:[NSMutableData class]])       return YYEncodingTypeNSMutableData;
    if ([cls isSubclassOfClass:[NSData class]])              return YYEncodingTypeNSData;
    if ([cls isSubclassOfClass:[NSDate class]])              return YYEncodingTypeNSDate;
    if ([cls isSubclassOfClass:[NSURL class]])               return YYEncodingTypeNSURL;
    if ([cls isSubclassOfClass:[NSMutableArray class]])      return YYEncodingTypeNSMutableArray;
    if ([cls isSubclassOfClass:[NSArray class]])             return YYEncodingTypeNSArray;
    if ([cls isSubclassOfClass:[NSMutableDictionary class]]) return YYEncodingTypeNSMutableDictionary;
    if ([cls isSubclassOfClass:[NSDictionary class]])        return YYEncodingTypeNSDictionary;
    if ([cls isSubclassOfClass:[NSMutableSet class]])        return YYEncodingTypeNSMutableSet;
    if ([cls isSubclassOfClass:[NSSet class]])               return YYEncodingTypeNSSet;
    return YYEncodingTypeNSUnknown;
}

/// Whether the type is c number.
AL_FORCE_INLINE BOOL _YYEncodingTypeIsCNumber(YYEncodingType type) {
    switch (type & YYEncodingTypeMask) {
        case YYEncodingTypeBool:
        case YYEncodingTypeInt8:
        case YYEncodingTypeUInt8:
        case YYEncodingTypeInt16:
        case YYEncodingTypeUInt16:
        case YYEncodingTypeInt32:
        case YYEncodingTypeUInt32:
        case YYEncodingTypeInt64:
        case YYEncodingTypeUInt64:
        case YYEncodingTypeFloat:
        case YYEncodingTypeDouble:
        case YYEncodingTypeLongDouble:
            return YES;
        default: return NO;
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

/// Parse string to date.
NSDate *_YYNSDateFromString(__unsafe_unretained NSString *string) {
    typedef NSDate* (^YYNSDateParseBlock)(NSString *string);
    #define kParserNum 34
    static YYNSDateParseBlock blocks[kParserNum + 1] = {0};
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        {
            /*
             2014-01-20  // Google
             */
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter.dateFormat = @"yyyy-MM-dd";
            blocks[10] = ^(NSString *string) { return [formatter dateFromString:string]; };
        }
        
        {
            /*
             2014-01-20 12:24:48
             2014-01-20T12:24:48   // Google
             2014-01-20 12:24:48.000
             2014-01-20T12:24:48.000
             */
            NSDateFormatter *formatter1 = [[NSDateFormatter alloc] init];
            formatter1.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter1.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter1.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss";
            
            NSDateFormatter *formatter2 = [[NSDateFormatter alloc] init];
            formatter2.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter2.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter2.dateFormat = @"yyyy-MM-dd HH:mm:ss";
            
            NSDateFormatter *formatter3 = [[NSDateFormatter alloc] init];
            formatter3.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter3.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter3.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS";
            
            NSDateFormatter *formatter4 = [[NSDateFormatter alloc] init];
            formatter4.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter4.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter4.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
            
            blocks[19] = ^(NSString *string) {
                if ([string characterAtIndex:10] == 'T') {
                    return [formatter1 dateFromString:string];
                } else {
                    return [formatter2 dateFromString:string];
                }
            };
            
            blocks[23] = ^(NSString *string) {
                if ([string characterAtIndex:10] == 'T') {
                    return [formatter3 dateFromString:string];
                } else {
                    return [formatter4 dateFromString:string];
                }
            };
        }
        
        {
            /*
             2014-01-20T12:24:48Z        // Github, Apple
             2014-01-20T12:24:48+0800    // Facebook
             2014-01-20T12:24:48+12:00   // Google
             2014-01-20T12:24:48.000Z
             2014-01-20T12:24:48.000+0800
             2014-01-20T12:24:48.000+12:00
             */
            NSDateFormatter *formatter = [NSDateFormatter new];
            formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
            
            NSDateFormatter *formatter2 = [NSDateFormatter new];
            formatter2.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter2.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZ";
            
            blocks[20] = ^(NSString *string) { return [formatter dateFromString:string]; };
            blocks[24] = ^(NSString *string) { return [formatter dateFromString:string]?: [formatter2 dateFromString:string]; };
            blocks[25] = ^(NSString *string) { return [formatter dateFromString:string]; };
            blocks[28] = ^(NSString *string) { return [formatter2 dateFromString:string]; };
            blocks[29] = ^(NSString *string) { return [formatter2 dateFromString:string]; };
        }
        
        {
            /*
             Fri Sep 04 00:12:21 +0800 2015 // Weibo, Twitter
             Fri Sep 04 00:12:21.000 +0800 2015
             */
            NSDateFormatter *formatter = [NSDateFormatter new];
            formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter.dateFormat = @"EEE MMM dd HH:mm:ss Z yyyy";
            
            NSDateFormatter *formatter2 = [NSDateFormatter new];
            formatter2.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter2.dateFormat = @"EEE MMM dd HH:mm:ss.SSS Z yyyy";
            
            blocks[30] = ^(NSString *string) { return [formatter dateFromString:string]; };
            blocks[34] = ^(NSString *string) { return [formatter2 dateFromString:string]; };
        }
    });
    if (!string) return nil;
    if (string.length > kParserNum) return nil;
    YYNSDateParseBlock parser = blocks[string.length];
    if (!parser) return nil;
    return parser(string);
    #undef kParserNum
}


/// Get the 'NSBlock' class.
Class _YYNSBlockClass() {
    static Class cls;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        void (^block)(void) = ^{};
        cls = ((NSObject *)block).class;
        while (class_getSuperclass(cls) != [NSObject class]) {
            cls = class_getSuperclass(cls);
        }
    });
    return cls; // current is "NSBlock"
}



/**
 Get the ISO date formatter.
 
 ISO8601 format example:
 2010-07-09T16:13:30+12:00
 2011-01-11T11:11:11+0000
 2011-01-26T19:06:43Z
 
 length: 20/24/25
 */
NSDateFormatter *_YYISODateFormatter() {
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
id _YYValueForKeyPath(__unsafe_unretained NSDictionary *dic, __unsafe_unretained NSArray *keyPaths) {
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
id _YYValueForMultiKeys(__unsafe_unretained NSDictionary *dic, __unsafe_unretained NSArray *multiKeys) {
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

BOOL _YYIsStructAvailableForKeyArchiver(NSString *structTypeEncoding) {
    static NSSet *availableTypes = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        availableTypes = [NSSet setWithObjects:
                                    // 32 bit
                                    @"{CGSize=ff}", @"{CGPoint=ff}", @"{CGRect={CGPoint=ff}{CGSize=ff}}",
                                    @"{CGAffineTransform=ffffff}", @"{UIEdgeInsets=ffff}", @"{UIOffset=ff}",
                                    // 64 bit
                                    @"{CGSize=dd}", @"{CGPoint=dd}", @"{CGRect={CGPoint=dd}{CGSize=dd}}",
                                    @"{CGAffineTransform=dddddd}", @"{UIEdgeInsets=dddd}", @"{UIOffset=dd}", nil];
    });
    return [availableTypes containsObject:structTypeEncoding];
}

BOOL _YYPropertyIsKVCCompatible(_ALModelPropertyMeta *meta) {
    if (meta->_getter && meta->_setter) {
        /*
         KVC invalid type:
         long double
         pointer (such as SEL/CoreFoundation object)
         */
        switch (meta->_type & YYEncodingTypeMask) {
            case YYEncodingTypeBool:
            case YYEncodingTypeInt8:
            case YYEncodingTypeUInt8:
            case YYEncodingTypeInt16:
            case YYEncodingTypeUInt16:
            case YYEncodingTypeInt32:
            case YYEncodingTypeUInt32:
            case YYEncodingTypeInt64:
            case YYEncodingTypeUInt64:
            case YYEncodingTypeFloat:
            case YYEncodingTypeDouble:
            case YYEncodingTypeObject:
            case YYEncodingTypeClass:
            case YYEncodingTypeBlock:
            case YYEncodingTypeStruct:
            case YYEncodingTypeUnion: {
                return YES;
            } break;
            default: break;
        }
    }
    return NO;
}

/**
 Set number to property.
 @discussion Caller should hold strong reference to the parameters before this function returns.
 @param model Should not be nil.
 @param num   Can be nil.
 @param meta  Should not be nil, meta.isCNumber should be YES, meta.setter should not be nil.
 */
AL_FORCE_INLINE void _ModelSetNumberToProperty(__unsafe_unretained id model, __unsafe_unretained NSNumber *num,
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

AL_FORCE_INLINE BOOL _ModelKVCSetValueForProperty(__unsafe_unretained id model,
                                                  __unsafe_unretained id value,
                                                  __unsafe_unretained _ALModelPropertyMeta *meta) {
    BOOL result = NO;
    if (meta->_isKVCCompatible) {
        @try {
            if (value) {
                [model setValue:value forKey:meta->_name];
            }
            result = YES;
        } @catch (NSException *e) {
            if ([e.name isEqualToString:_ALNSUnknownKeyException]) {
                meta->_isKVCCompatible = NO;
            }
        }
    }
    return result;
}

/**
 Set value to model with a property meta.
 
 @discussion Caller should hold strong reference to the parameters before this function returns.
 
 @param model Should not be nil.
 @param value Should not be nil, but can be NSNull.
 @param meta  Should not be nil, and meta->_setter should not be nil.
 */
AL_FORCE_INLINE void _ModelSetValueForProperty(__unsafe_unretained id model,
                                               __unsafe_unretained id value,
                                               __unsafe_unretained _ALModelPropertyMeta *meta,
                                               __unsafe_unretained Class _Nullable genericClass,
                                               SEL _Nullable customClassForDictionarySelector) {
    
    if (meta->_setter == nil) {
        _ModelKVCSetValueForProperty(model, value, meta);
        return;
    }
    
    if (meta->_isCNumber) {
        NSNumber *num = _YYNSNumberCreateFromID(value);
        _ModelSetNumberToProperty(model, num, meta);
        if (num) {  // hold the number
            [num class];
        }
    } else if (meta->_nsType) {
        if (value == (id) kCFNull) {
            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter, (id) nil);
        } else {
            switch (meta->_nsType) {
                case YYEncodingTypeNSString:
                case YYEncodingTypeNSMutableString: {
                    if ([value isKindOfClass:[NSString class]]) {
                        if (meta->_nsType == YYEncodingTypeNSString) {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter, value);
                        } else {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter,
                                                                           ((NSString *) value).mutableCopy);
                        }
                    } else if ([value isKindOfClass:[NSNumber class]]) {
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)(
                            (id) model, meta->_setter, (meta->_nsType == YYEncodingTypeNSString)
                                                           ? ((NSNumber *) value).stringValue
                                                           : ((NSNumber *) value).stringValue.mutableCopy);
                    } else if ([value isKindOfClass:[NSData class]]) {
                        NSMutableString *string =
                            [[NSMutableString alloc] initWithData:value encoding:NSUTF8StringEncoding];
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter, string);
                    } else if ([value isKindOfClass:[NSURL class]]) {
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)(
                            (id) model, meta->_setter, (meta->_nsType == YYEncodingTypeNSString)
                                                           ? ((NSURL *) value).absoluteString
                                                           : ((NSURL *) value).absoluteString.mutableCopy);
                    } else if ([value isKindOfClass:[NSAttributedString class]]) {
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)(
                            (id) model, meta->_setter, (meta->_nsType == YYEncodingTypeNSString)
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
                        if (meta->_nsType == YYEncodingTypeNSData) {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter, value);
                        } else {
                            NSMutableData *data = ((NSData *) value).mutableCopy;
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter, data);
                        }
                    } else if ([value isKindOfClass:[NSString class]]) {
                        NSData *data = [(NSString *) value dataUsingEncoding:NSUTF8StringEncoding];
                        if (meta->_nsType == YYEncodingTypeNSMutableData) {
                            data = ((NSData *) data).mutableCopy;
                        }
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter, data);
                    }
                } break;
                    
                case YYEncodingTypeNSDate: {
                    if ([value isKindOfClass:[NSDate class]]) {
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter, value);
                    } else if ([value isKindOfClass:[NSString class]]) {
                        NSDate *d = _YYNSDateFromString(value);
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
                            if (meta->_nsType == YYEncodingTypeNSArray) {
                                ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter, value);
                            } else {
                                ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, meta->_setter,
                                                                               ((NSArray *) value).mutableCopy);
                            }
                        } else if ([value isKindOfClass:[NSSet class]]) {
                            if (meta->_nsType == YYEncodingTypeNSArray) {
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
                            if (meta->_nsType == YYEncodingTypeNSDictionary) {
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
                        if (meta->_nsType == YYEncodingTypeNSSet) {
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
//                ALLogError(@"Model \"%@\" can not set value for property:\"%@\"", [model class], meta->_name);
                break;
            }
        }
    }
}

/**
 Get number from property.
 @discussion Caller should hold strong reference to the parameters before this function returns.
 @param model Should not be nil.
 @param meta  Should not be nil, meta.isCNumber should be YES, meta.getter should not be nil.
 @return A number object, or nil if failed.
 */
AL_FORCE_INLINE NSNumber *_ModelCreateNumberFromProperty(__unsafe_unretained id model,
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

@implementation _ALModelHelper

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

+ (NSSet<NSString *> *)model:(Class)cls propertySetWithSelector:(SEL)propertyListSelector {
    NSArray *properties = al_safeInvokeSelector(NSArray *, cls, propertyListSelector);
    if ([properties isKindOfClass:NSArray.class]) {
        return [NSSet setWithArray:properties];
    }
    return nil;
}

@end

