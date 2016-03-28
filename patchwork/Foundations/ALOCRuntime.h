//
//  ALOCRuntime.h
//  patchwork
//
//  Created by Alex Lee on 2/24/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YYClassInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface ALOCRuntime : NSObject

+ (NSSet<Class> *)classConfirmsToProtocol:(Protocol *)protocol;
+ (NSSet<Class> *)subClassesOf:(Class)clazz;

+ (NSDictionary<NSString *, YYClassPropertyInfo *> *)propertiesOfProtocol:(Protocol *)protocol;

@end


@interface NSObject (ClassMetasExtension)

+ (Class)commonAncestorWithClass:(Class)other;
+ (NSArray<Class> *)ancestorClasses;

+ (NSDictionary<NSString *, YYClassPropertyInfo *> *)allProperties;
+ (NSDictionary<NSString *, YYClassIvarInfo *> *)allIvars;
+ (NSDictionary<NSString *, YYClassMethodInfo *> *)allMethods;

+ (BOOL)hasProperty:(NSString *)propertyName;

- (__kindof NSObject *_Nonnull (^)(NSString *_Nonnull propertyName, id _Nullable propertyValue))SET_PROPERTY;
@end

NS_ASSUME_NONNULL_END