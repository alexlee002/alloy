//
//  __ALModelMeta.h
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
#import "__ALModelHelper.h"

NS_ASSUME_NONNULL_BEGIN

@interface _ALModelPropertyMeta : NSObject {
  @package
    NSString                *_name;
    YYEncodingType          _type;
    _YYEncodingNSType       _nsType;            // property's Foundation type.
    BOOL                    _isCNumber;         // is C Number type?
    Class _Nullable         _cls;
    YYClassPropertyInfo     *_info;
    SEL _Nullable           _setter;            // nil if the instances selector cannot respond
    SEL _Nullable           _getter;            // nil if the instances selector cannot respond
    BOOL                    _isKVCCompatible;
}

+ (instancetype)metaWithClassInfo:(YYClassInfo *)classInfo propertyInfo:(YYClassPropertyInfo *)propertyInfo;
@end

//////////////////////////////////////////////////////////////////////////////////

@interface _ALModelMeta : NSObject {
  @package
    YYClassInfo                                             *_classInfo;
    _YYEncodingNSType                                        _nsType;
    //including jSON & ActiveRecord
    NSDictionary<NSString *, _ALModelPropertyMeta *>        *_allPropertyMetasDict;
}

+ (instancetype)metaWithClass:(Class)cls;
@end

NS_ASSUME_NONNULL_END

