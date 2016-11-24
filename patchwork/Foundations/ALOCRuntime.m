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
#include <execinfo.h>
#include <sys/sysctl.h>

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

FORCE_INLINE BOOL classIsSubClassOfClass(Class subCls, Class cls) {
    while ((subCls = class_getSuperclass(subCls)) != nil) {
        if (cls == subCls) {
            return YES;
        }
    }
    return NO;
}

FORCE_INLINE NSArray<NSString *> *backtraceStack(int size) {
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
FORCE_INLINE BOOL debuggerFound() {
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
        return classIsSubClassOfClass(cls, clazz);
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
    return [[[[[self ancestorClasses] al_zip:[other ancestorClasses], nil] bk_select:^BOOL(NSArray<Class> *obj) {
        return (obj.count == 2 && obj.firstObject == obj.lastObject);
    }] lastObject] firstObject] ?: NSObject.class;
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
