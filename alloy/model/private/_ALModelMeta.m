//
//  _ALModelMeta.m
//  alloy
//
//  Created by Alex Lee on 06/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "_ALModelMeta.h"
#import "ALMacros.h"

/// Get the Foundation class type from property info.
static AL_FORCE_INLINE _YYEncodingNSType _YYClassGetNSType(Class cls) {
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
static AL_FORCE_INLINE BOOL _YYEncodingTypeIsCNumber(YYEncodingType type) {
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
static NSNumber *_YYNSNumberCreateFromID(__unsafe_unretained id value) {
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

static BOOL _YYPropertyIsKVCCompatible(_ALModelPropertyMeta *meta) {
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

@implementation _ALModelPropertyMeta
+ (instancetype)metaWithClassInfo:(YYClassInfo *)classInfo propertyInfo:(YYClassPropertyInfo *)propertyInfo {
    _ALModelPropertyMeta *meta = [[self alloc] init];
    meta->_name                = propertyInfo.name;
    meta->_type                = propertyInfo.type;
    meta->_info                = propertyInfo;
    meta->_cls                 = propertyInfo.cls;
    
    if ((meta->_type & YYEncodingTypeMask) == YYEncodingTypeObject) {
        meta->_NSType = _YYClassGetNSType(propertyInfo.cls);
    } else {
        meta->_isCNumber = _YYEncodingTypeIsCNumber(meta->_type);
    }
    
    if (propertyInfo.getter && [classInfo.cls instancesRespondToSelector:propertyInfo.getter]) {
        meta->_getter = propertyInfo.getter;
    }
    
    if (propertyInfo.setter && [classInfo.cls instancesRespondToSelector:propertyInfo.setter]) {
        meta->_setter = propertyInfo.setter;
    }
    
    meta->_isKVCCompatible = _YYPropertyIsKVCCompatible(meta);
    
    return meta;
}

@end

@implementation _ALModelMeta
+ (instancetype)metaWithClass:(Class)cls {
    if (!cls) {
        return nil;
    }
    
    static CFMutableDictionaryRef cache;
    static dispatch_semaphore_t lock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = CFDictionaryCreateMutable(CFAllocatorGetDefault(),
                                          0,
                                          &kCFTypeDictionaryKeyCallBacks,
                                          &kCFTypeDictionaryValueCallBacks);
        lock = dispatch_semaphore_create(1);
    });
    
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    _ALModelMeta *meta = CFDictionaryGetValue(cache, (__bridge const void *) (cls));
    dispatch_semaphore_signal(lock);
    
    if (!meta || meta->_info.needUpdate) {
        meta = [[_ALModelMeta alloc] initWithClass:cls];
        if (meta) {
            dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
            CFDictionarySetValue(cache, (__bridge const void *) (cls), (__bridge const void *) (meta));
            dispatch_semaphore_signal(lock);
        }
    }
    return meta;
}

- (instancetype)initWithClass:(Class)cls {
    YYClassInfo *classInfo = [YYClassInfo classInfoWithClass:cls];
    if (!classInfo) {
        return nil;
    }

    self = [super init];
    if (self) {
        _info   = classInfo;
        _NSType = _YYClassGetNSType(cls);
        [self loadAllPropertyMetas];
    }
    return self;
}

- (void)loadAllPropertyMetas {
    NSMutableDictionary<NSString *, _ALModelPropertyMeta *> *allPropertiesDict = [NSMutableDictionary dictionary];
    YYClassInfo *tmpClassInfo = _info;
    while (tmpClassInfo /*&& tmpClassInfo.superCls != nil*/) {  // FIXME: should ignore root class(NSObject/JSProxy)?
        for (YYClassPropertyInfo *propertyInfo in tmpClassInfo.propertyInfos.allValues) {
            if (!propertyInfo.name) {
                continue;
            }
            
            if (tmpClassInfo.cls == NSObject.class || tmpClassInfo.cls == NSProxy.class) {
                static NSSet<NSString *> *kIgnoreProperties = nil;
                static dispatch_once_t onceToken;
                dispatch_once(&onceToken, ^{
                    kIgnoreProperties = [NSSet setWithObjects:
                                         @"accessibilityActivationPoint",
                                         @"accessibilityCustomActions",
                                         @"accessibilityCustomRotors",
                                         @"accessibilityElements",
                                         @"accessibilityElementsHidden",
                                         @"accessibilityFrame",
                                         @"accessibilityHeaderElements",
                                         @"accessibilityHint",
                                         @"accessibilityIdentifier",
                                         @"accessibilityLabel",
                                         @"accessibilityLanguage",
                                         @"accessibilityNavigationStyle",
                                         @"accessibilityPath",
                                         @"accessibilityTraits",
                                         @"accessibilityValue",
                                         @"accessibilityAttributedHint",
                                         @"accessibilityAttributedLabel",
                                         @"accessibilityAttributedValue",
                                         @"accessibilityContainerType",
                                         @"accessibilityLocalizedStringKey",
                                         @"accessibilityViewIsModal",
                                         @"autoContentAccessingProxy",
                                         @"classForKeyedArchiver",
                                         @"isAccessibilityElement",
                                         @"observationInfo",
                                         @"shouldGroupAccessibilityChildren",
                                         @"traitStorageList",
                                         @"_ui_descriptionBuilder",
                                         nil];
                });
                
                if ([kIgnoreProperties containsObject:propertyInfo.name]) {
                    continue;
                }
            }
            
            if ([@[@"debugDescription", @"description", @"hash", @"superclass",] containsObject:propertyInfo.name]) {
                continue;
            }
            
            _ALModelPropertyMeta *propertyMeta =
            [_ALModelPropertyMeta metaWithClassInfo:_info propertyInfo:propertyInfo];
            
            if (!propertyMeta || !propertyMeta->_name) {
                continue;
            }
            if (allPropertiesDict[propertyMeta->_name]) {
                continue;
            }
            allPropertiesDict[propertyMeta->_name] = propertyMeta;
        }
        if (tmpClassInfo.superCls == nil) {
            break;
        }
        tmpClassInfo = tmpClassInfo.superClassInfo;
    }
    if (allPropertiesDict.count > 0) {
        _allPropertyMetasDict = [allPropertiesDict copy];
    }
}

@end
