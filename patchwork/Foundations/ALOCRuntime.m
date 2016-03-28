//
//  ALOCRuntime.m
//  patchwork
//
//  Created by Alex Lee on 2/24/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALOCRuntime.h"
#import "YYClassInfo.h"
#import "BlocksKitExtension.h"
#import "BlocksKit.h"
#import "UtilitiesHeader.h"

NS_ASSUME_NONNULL_BEGIN

FORCE_INLINE static NSSet<Class> *filterClassesWithBlock(BOOL (^block)(Class cls)) {
    NSMutableSet *set = [NSMutableSet set];
    unsigned int classesCount = 0;
    Class *classes = objc_copyClassList( &classesCount );
    for (int i = 0; i < classesCount; ++i) {
        Class clazz = classes[i];
        Class superClass = class_getSuperclass(clazz);
        
        if (nil == superClass) {
            continue;
        }
        if (!class_respondsToSelector(clazz, @selector(doesNotRecognizeSelector:))) {
            continue;
        }
        if (!class_respondsToSelector(clazz, @selector(methodSignatureForSelector:))) {
            continue;
        }
        
        if (block && block(clazz)) {
            [set addObject:clazz];
        }
    }
    free(classes);
    
    return set;
}

@implementation ALOCRuntime

+ (NSSet<Class> *)classConfirmsToProtocol:(Protocol *)protocol {
    if (protocol == nil) {
        return nil;
    }
    return filterClassesWithBlock(^BOOL(__unsafe_unretained Class cls) {
        return [cls conformsToProtocol:protocol];
    });
}

+ (NSSet<Class> *)subClassesOf:(Class)clazz {
    if (clazz == nil) {
        return nil;
    }
    return filterClassesWithBlock(^BOOL(__unsafe_unretained Class cls) {
        return [cls isSubclassOfClass:clazz];
    });
}

+ (NSDictionary<NSString *, YYClassPropertyInfo *> *)propertiesOfProtocol:(Protocol *)protocol {
    if (protocol == nil) {
        return nil;
    }
    unsigned int count = 0;
    objc_property_t *properties =protocol_copyPropertyList(protocol, &count);
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:count];
    for (int i = 0; i < count; ++i) {
        objc_property_t p = properties[i];
        YYClassPropertyInfo *propertyInfo = [[YYClassPropertyInfo alloc]initWithProperty:p];
        dict[propertyInfo.name] = propertyInfo;
    }
    free(properties);
    return dict;
}

@end



@implementation NSObject (ClassMetasExtension)

+ (Class)commonAncestorWithClass:(Class)other {
    return [[[[self ancestorClasses] al_zip:[other ancestorClasses], nil] bk_match:^BOOL(NSArray<Class> *obj) {
        return !(obj.count == 2 && obj.firstObject == obj.lastObject);
    }] firstObject] ?: NSObject.class;
}

+ (NSArray<Class> *)ancestorClasses {
    NSMutableArray<Class> *classes = [NSMutableArray array];
    Class clazz = self;
    while (clazz != nil) {
        [classes insertObject:clazz atIndex:0];
        clazz = [clazz superclass];
    }
    return classes;
}


+ (NSDictionary<NSString *, YYClassPropertyInfo *> *)allProperties {
    NSMutableDictionary<NSString *, YYClassPropertyInfo *> *allProperties = [NSMutableDictionary dictionary];
    NSArray<Class> *ancestors = [self ancestorClasses];
    for (Class clazz in ancestors) {
        YYClassInfo *info = [YYClassInfo classInfoWithClass:clazz];
        [allProperties addEntriesFromDictionary:info.propertyInfos];
    }
    return allProperties;
}

+ (NSDictionary<NSString *, YYClassIvarInfo *> *)allIvars {
    NSMutableDictionary<NSString *, YYClassIvarInfo *> *allIvars = [NSMutableDictionary dictionary];
    NSArray<Class> *ancestors = [self ancestorClasses];
    for (Class clazz in ancestors) {
        YYClassInfo *info = [YYClassInfo classInfoWithClass:clazz];
        [allIvars addEntriesFromDictionary:info.ivarInfos];
    }
    return allIvars;
}

+ (NSDictionary<NSString *, YYClassMethodInfo *> *)allMethods {
    NSMutableDictionary<NSString *, YYClassMethodInfo *> *allMethods = [NSMutableDictionary dictionary];
    NSArray<Class> *ancestors = [self ancestorClasses];
    for (Class clazz in ancestors) {
        YYClassInfo *info = [YYClassInfo classInfoWithClass:clazz];
        [allMethods addEntriesFromDictionary:info.methodInfos];
    }
    return allMethods;
}

+ (BOOL)hasProperty:(NSString *)propertyName {
    return [self allProperties][propertyName] != nil;
}

- (__kindof NSObject *_Nonnull (^)(NSString *_Nonnull propertyName, id _Nullable propertyValue))SET_PROPERTY {
    return ^NSObject *_Nonnull (NSString *_Nonnull propertyName, id _Nullable propertyValue) {
        [self setValue:propertyValue forKey:propertyName];
        return self;
    };
}

@end

NS_ASSUME_NONNULL_END