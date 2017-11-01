//
//  _ALModelMeta.h
//  alloy
//
//  Created by Alex Lee on 06/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//
//  IMPORTANT:
//  The implementation of JSON & model mapping is very much inspired by YYModel(@link: https://github.com/ibireme/YYModel ).
//  Thanks @Yaoyuan (@link: https://github.com/ibireme )!
//  The copyright of the code from YYModel is reserved by @Yaoyuan.
//

#import <Foundation/Foundation.h>
#import "YYClassInfo.h"

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

NS_ASSUME_NONNULL_BEGIN

@interface _ALModelPropertyMeta : NSObject {
  @package
    NSString               *_name;          // property name
    YYEncodingType          _type;          // encoding type
    _YYEncodingNSType       _NSType;        // ObjC type
    BOOL                    _isCNumber;     // c/cpp numeric type
    Class _Nullable         _cls;           // property's ObjC class
    SEL _Nullable           _setter;        // nil if the instances selector cannot respond
    SEL _Nullable           _getter;
    BOOL                    _isKVCCompatible;
    YYClassPropertyInfo    *_info;
}

+ (instancetype)metaWithClassInfo:(YYClassInfo *)classInfo propertyInfo:(YYClassPropertyInfo *)propertyInfo;
@end

//////////////////////////////////////////////////////////////////////////////////

@interface _ALModelMeta : NSObject {
  @package
    YYClassInfo            *_info;
    _YYEncodingNSType       _NSType;
    NSDictionary<NSString *, _ALModelPropertyMeta *> *_allPropertyMetasDict;
}

+ (instancetype)metaWithClass:(Class)cls;

@end

NS_ASSUME_NONNULL_END
