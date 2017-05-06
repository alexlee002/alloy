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
#import "ALUtilitiesHeader.h"
#include <execinfo.h>
#include <sys/sysctl.h>
#import "ALLogger.h"

NS_ASSUME_NONNULL_BEGIN

AL_FORCE_INLINE BOOL al_swizzle_method(Class cls, BOOL isClassMethod, SEL originalSEL, SEL swizzledSEL) {
    Method originalMethod = isClassMethod ? class_getClassMethod(cls, originalSEL) : class_getInstanceMethod(cls, originalSEL);
    Method swizzledMethod = isClassMethod ? class_getClassMethod(cls, swizzledSEL) : class_getInstanceMethod(cls, swizzledSEL);
    
    if (originalMethod == NULL) {
        ALLogError(@"class %@, selector:%@; method not found!", cls, NSStringFromSelector(originalSEL));
        return NO;
    }
    if (swizzledMethod == NULL) {
        ALLogError(@"class %@, selector:%@; method not found!", cls, NSStringFromSelector(swizzledSEL));
        return NO;
    }
    
    if (isClassMethod) {
        cls = object_getClass(cls);
    }
    
    BOOL methodDidAdd = class_addMethod(cls, originalSEL, method_getImplementation(swizzledMethod),
                                        method_getTypeEncoding(swizzledMethod));
    if (methodDidAdd) {
        class_replaceMethod(cls, swizzledSEL, method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
    return YES;
}

AL_FORCE_INLINE BOOL al_classIsSubClassOfClass(Class subCls, Class cls) {
    while ((subCls = class_getSuperclass(subCls)) != nil) {
        if (cls == subCls) {
            return YES;
        }
    }
    return NO;
}

AL_FORCE_INLINE NSArray<NSString *> *al_backtraceStack(int size) {
    size = size > 0 ? size : 128;
    void* callstack[size];
    int frames = backtrace(callstack, size);
    char **symbols = backtrace_symbols(callstack, frames);
    
    int i;
    NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frames];
    for (i = 0; i < frames; ++i) {
        NSString *line = [NSString stringWithUTF8String:symbols[i]];
        if (line == nil) {
            break;
        }
        [backtrace addObject:line];
    }
    
    free(symbols);
    
    return backtrace;
}

// @see http://stackoverflow.com/questions/4744826/detecting-if-ios-app-is-run-in-debugger
AL_FORCE_INLINE BOOL al_debuggerFound() {
    // Initialize the flags so that, if sysctl fails for some bizarre
    // reason, we get a predictable result.
    struct kinfo_proc info;
    info.kp_proc.p_flag = 0;
    
    // Initialize mib, which tells sysctl the info we want, in this case
    // we're looking for information about a specific process ID.
    int mib[4];
    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC;
    mib[2] = KERN_PROC_PID;
    mib[3] = getpid();
    
    // Call sysctl.
    size_t size = sizeof(info);
    int junk = sysctl(mib, sizeof(mib) / sizeof(*mib), &info, &size, NULL, 0);
#if DEBUG
    assert(junk == 0);
#else
    return NO; //default return NO
#endif
    // We're being debugged if the P_TRACED flag is set.
    return ( (info.kp_proc.p_flag & P_TRACED) != 0 );
}


// @see http://blog.sunnyxx.com/2015/09/13/class-ivar-layout/
// @see -[FoundationsTests testFakeClass]
AL_FORCE_INLINE void al_fixup_class_arc(Class class) {
    struct {
        Class isa;
        Class superclass;
        struct {
            void *_buckets;
#if __LP64__
            uint32_t _mask;
            uint32_t _occupied;
#else
            uint16_t _mask;
            uint16_t _occupied;
#endif
        } cache;
        uintptr_t bits;
    } *objcClass = (__bridge typeof(objcClass))class;
#if !__LP64__
#define FAST_DATA_MASK 0xfffffffcUL
#else
#define FAST_DATA_MASK 0x00007ffffffffff8UL
#endif
    struct {
        uint32_t flags;
        uint32_t version;
        struct {
            uint32_t flags;
        } *ro;
    } *objcRWClass = (typeof(objcRWClass))(objcClass->bits & FAST_DATA_MASK);
#define RO_IS_ARR 1<<7
    objcRWClass->ro->flags |= RO_IS_ARR;
}

void al_registerArcClassPair(Class cls) {
    if (cls != NULL) {
        objc_registerClassPair(cls);
        al_fixup_class_arc(cls);
    }
}

//private function
AL_FORCE_INLINE static NSSet<Class> *filterClassesWithBlock(BOOL (^block)(Class cls)) {
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
        return class_conformsToProtocol(cls, protocol);
    });
}

+ (NSSet<Class> *)subClassesOf:(Class)clazz {
    if (clazz == nil) {
        return nil;
    }
    return filterClassesWithBlock(^BOOL(__unsafe_unretained Class cls) {
        return al_classIsSubClassOfClass(cls, clazz);
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

+ (Class)al_commonAncestorWithClass:(Class)other {
    return [[[[[self al_ancestorClasses] al_zip:[other al_ancestorClasses], nil] bk_select:^BOOL(NSArray<Class> *obj) {
        return (obj.count == 2 && obj.firstObject == obj.lastObject);
    }] lastObject] firstObject] ?: NSObject.class;
}

+ (NSArray<Class> *)al_ancestorClasses {
    NSMutableArray<Class> *classes = [NSMutableArray array];
    Class clazz = self;
    while (clazz != nil) {
        [classes insertObject:clazz atIndex:0];
        clazz = [clazz superclass];
    }
    return classes;
}


+ (NSDictionary<NSString *, YYClassPropertyInfo *> *)al_allProperties {
    NSMutableDictionary<NSString *, YYClassPropertyInfo *> *allProperties = [NSMutableDictionary dictionary];
    NSArray<Class> *ancestors = [self al_ancestorClasses];
    for (Class clazz in ancestors) {
        YYClassInfo *info = [YYClassInfo classInfoWithClass:clazz];
        [allProperties addEntriesFromDictionary:info.propertyInfos];
    }
    return allProperties;
}

+ (NSDictionary<NSString *, YYClassIvarInfo *> *)al_allIvars {
    NSMutableDictionary<NSString *, YYClassIvarInfo *> *allIvars = [NSMutableDictionary dictionary];
    NSArray<Class> *ancestors = [self al_ancestorClasses];
    for (Class clazz in ancestors) {
        YYClassInfo *info = [YYClassInfo classInfoWithClass:clazz];
        [allIvars addEntriesFromDictionary:info.ivarInfos];
    }
    return allIvars;
}

+ (NSDictionary<NSString *, YYClassMethodInfo *> *)al_allMethods {
    NSMutableDictionary<NSString *, YYClassMethodInfo *> *allMethods = [NSMutableDictionary dictionary];
    NSArray<Class> *ancestors = [self al_ancestorClasses];
    for (Class clazz in ancestors) {
        YYClassInfo *info = [YYClassInfo classInfoWithClass:clazz];
        [allMethods addEntriesFromDictionary:info.methodInfos];
    }
    return allMethods;
}

+ (BOOL)al_hasProperty:(NSString *)propertyName {
    return [self al_allProperties][propertyName] != nil;
}

- (__kindof NSObject *_Nonnull (^)(NSString *_Nonnull propertyName, id _Nullable propertyValue))SET_PROPERTY {
    return ^NSObject *_Nonnull (NSString *_Nonnull propertyName, id _Nullable propertyValue) {
        [self setValue:propertyValue forKey:propertyName];
        return self;
    };
}

@end

NS_ASSUME_NONNULL_END
