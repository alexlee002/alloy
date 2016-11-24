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

#if __IPHONE_8_0 || __MAC_10_10
#   define isClassObject(obj) object_isClass((obj))
#else
#   define isClassObject(obj) class_isMetaClass(object_getClass((obj)))
#endif

#ifndef primitiveSelectorResult
    #define primitiveSelectorResult(ret_type, obj, sel, ...) \
        ((ret_type (*)(id, SEL))(void *) objc_msgSend)((id)(obj), (sel), ##__VA_ARGS__)
#endif

extern NSArray<NSString *> *backtraceStack(int stackSize);
extern BOOL debuggerFound();
extern BOOL classIsSubClassOfClass(Class subCls, Class cls);

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
