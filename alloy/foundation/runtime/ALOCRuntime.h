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
#   define al_isClassObject(obj) object_isClass((obj))
#else
#   define al_isClassObject(obj) class_isMetaClass(object_getClass((obj)))
#endif

//#ifndef al_performSelector
//    #define al_performSelector(return_type, obj, sel, ...) \
//        ((return_type (*)(id, SEL))(void *) objc_msgSend)((id)(obj), (sel), ##__VA_ARGS__)
//#endif

extern BOOL al_swizzle_method(Class cls, BOOL isClassMethod, SEL originalSEL, SEL swizzledSEL);

extern NSArray<NSString *> *al_backtraceStack(int stackSize);
extern BOOL al_debuggerFound(void);
extern BOOL al_classIsSubClassOfClass(Class subCls, Class cls);
extern void al_fixup_class_arc(Class cls);
extern void al_registerArcClassPair(Class cls);

@interface ALOCRuntime : NSObject

+ (NSSet<Class> *)classConfirmsToProtocol:(Protocol *)protocol;
+ (NSSet<Class> *)subClassesOf:(Class)clazz;

+ (NSDictionary<NSString *, YYClassPropertyInfo *> *)propertiesOfProtocol:(Protocol *)protocol;

@end


@interface NSObject (ClassMetasExtension)

+ (Class)al_commonAncestorWithClass:(Class)other;
+ (NSArray<Class> *)al_ancestorClasses;

+ (NSDictionary<NSString *, YYClassPropertyInfo *> *)al_allProperties;
+ (NSDictionary<NSString *, YYClassIvarInfo *> *)al_allIvars;
+ (NSDictionary<NSString *, YYClassMethodInfo *> *)al_allMethods;

+ (BOOL)al_hasProperty:(NSString *)propertyName;

- (__kindof NSObject *_Nonnull (^)(NSString *_Nonnull propertyName, id _Nullable propertyValue))SET_PROPERTY;
@end

NS_ASSUME_NONNULL_END
