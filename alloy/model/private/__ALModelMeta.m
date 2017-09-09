//
//  __ALModelMeta.m
//  patchwork
//
//  Created by Alex Lee on 09/06/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "__ALModelMeta.h"

@implementation _ALModelPropertyMeta
+ (instancetype)metaWithClassInfo:(YYClassInfo *)classInfo propertyInfo:(YYClassPropertyInfo *)propertyInfo {
    _ALModelPropertyMeta *meta = [[self alloc] init];
    meta->_name                = propertyInfo.name;
    meta->_type                = propertyInfo.type;
    meta->_info                = propertyInfo;
    meta->_cls                 = propertyInfo.cls;
    
    if ((meta->_type & YYEncodingTypeMask) == YYEncodingTypeObject) {
        meta->_nsType = _YYClassGetNSType(propertyInfo.cls);
    } else {
        meta->_isCNumber = _YYEncodingTypeIsCNumber(meta->_type);
    }
    
    if (propertyInfo.getter && [classInfo.cls instancesRespondToSelector:propertyInfo.getter]) {
        meta->_getter = propertyInfo.getter;
    }
    
    if (propertyInfo.setter && [classInfo.cls instancesRespondToSelector:propertyInfo.setter]) {
        meta->_setter = propertyInfo.setter;
    }
    
    meta->_isKVCCompatible = YES;
    
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
        cache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks,
                                          &kCFTypeDictionaryValueCallBacks);
        lock = dispatch_semaphore_create(1);
    });
    
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    _ALModelMeta *meta = CFDictionaryGetValue(cache, (__bridge const void *) (cls));
    dispatch_semaphore_signal(lock);
    
    if (!meta || meta->_classInfo.needUpdate) {
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
        _classInfo = classInfo;
        _nsType    = _YYClassGetNSType(cls);
        [self loadAllPropertyMetas];
    }
    return self;
}

- (void)loadAllPropertyMetas {
    NSMutableDictionary<NSString *, _ALModelPropertyMeta *> *allPropertiesDict = [NSMutableDictionary dictionary];
    YYClassInfo *tmpClassInfo = _classInfo;
    while (tmpClassInfo /*&& tmpClassInfo.superCls != nil*/) {  // FIXME: should ignore root class(NSObject/JSProxy)?
        for (YYClassPropertyInfo *propertyInfo in tmpClassInfo.propertyInfos.allValues) {
            if (!propertyInfo.name) {
                continue;
            }
            _ALModelPropertyMeta *propertyMeta =
                [_ALModelPropertyMeta metaWithClassInfo:_classInfo propertyInfo:propertyInfo];
            
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
