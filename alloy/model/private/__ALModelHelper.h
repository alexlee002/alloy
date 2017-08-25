//
//  __ALModelHelper.h
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

#import <Foundation/Foundation.h>
#import "YYClassInfo.h"

NS_ASSUME_NONNULL_BEGIN

/// Foundation Class Type
typedef NS_ENUM (NSUInteger, _YYEncodingNSType) {
    YYEncodingTypeNSUnknown = 0,
    YYEncodingTypeNSString,
    YYEncodingTypeNSMutableString,
    YYEncodingTypeNSValue,
    YYEncodingTypeNSNumber,
    YYEncodingTypeNSDecimalNumber,
    YYEncodingTypeNSData,
    YYEncodingTypeNSMutableData,
    YYEncodingTypeNSDate,
    YYEncodingTypeNSURL,
    YYEncodingTypeNSArray,
    YYEncodingTypeNSMutableArray,
    YYEncodingTypeNSDictionary,
    YYEncodingTypeNSMutableDictionary,
    YYEncodingTypeNSSet,
    YYEncodingTypeNSMutableSet,
};

OBJC_EXPORT NSString *const _ALNSUnknownKeyException;

OBJC_EXPORT _YYEncodingNSType _YYClassGetNSType(Class cls);
OBJC_EXPORT BOOL _YYEncodingTypeIsCNumber(YYEncodingType type);
OBJC_EXPORT NSNumber *_YYNSNumberCreateFromID(__unsafe_unretained id value);
OBJC_EXPORT NSDate *_YYNSDateFromString(__unsafe_unretained NSString *string);
OBJC_EXPORT Class _YYNSBlockClass(void);
OBJC_EXPORT NSDateFormatter *_YYISODateFormatter(void);
OBJC_EXPORT id _YYValueForKeyPath(__unsafe_unretained NSDictionary *dic, __unsafe_unretained NSArray *keyPaths);
OBJC_EXPORT id _YYValueForMultiKeys(__unsafe_unretained NSDictionary *dic, __unsafe_unretained NSArray *multiKeys);
OBJC_EXPORT BOOL _YYIsStructAvailableForKeyArchiver(NSString *structTypeEncoding);

@class _ALModelPropertyMeta;
OBJC_EXPORT BOOL _YYPropertyIsKVCCompatible(_ALModelPropertyMeta *meta);
OBJC_EXPORT void _ModelSetNumberToProperty(__unsafe_unretained id model,
                                           __unsafe_unretained NSNumber *num,
                                           __unsafe_unretained _ALModelPropertyMeta *meta);

OBJC_EXPORT void _ModelSetValueForProperty(__unsafe_unretained id model,
                                           __unsafe_unretained id value,
                                           __unsafe_unretained _ALModelPropertyMeta *meta,
                                           __unsafe_unretained Class _Nullable genericClass,
                                           SEL _Nullable customClassForDictionarySelector);

OBJC_EXPORT BOOL _ModelKVCSetValueForProperty(__unsafe_unretained id model,
                                              __unsafe_unretained id value,
                                              __unsafe_unretained _ALModelPropertyMeta *meta);

OBJC_EXPORT NSNumber *_ModelCreateNumberFromProperty(__unsafe_unretained id model,
                                                     __unsafe_unretained _ALModelPropertyMeta *meta);

#pragma mark -
@interface _ALModelHelper : NSObject

+ (nullable NSDictionary *)dictionaryFromJSON:(id)json;

+ (NSSet<NSString *> *)model:(Class)modelClass propertySetWithSelector:(SEL)propertyListSelector;

@end

NS_ASSUME_NONNULL_END
