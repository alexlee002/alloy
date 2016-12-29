//
//  Singleton_Template.h
//  patchwork
//
//  Created by Alex Lee on 3/11/15.
//  Copyright © 2015 Alex Lee. All rights reserved.
//

#undef  AS_SINGLETON
#define AS_SINGLETON                    \
        + (instancetype)sharedInstance; \



#undef  SYNTHESIZE_SINGLETON
#if __has_feature(objc_arc)
    #define SYNTHESIZE_SINGLETON  __AL_SYNTHESIZE_SINGLETON
#else
    #define SYNTHESIZE_SINGLETON                            \
        __AL_SYNTHESIZE_SINGLETON                           \
                                                            \
        - (instancetype)retain {  return self; }            \
        - (oneway void)release {}                           \
        - (instancetype)autorelease { return self; }        \
        - (NSUInteger)retainCount { return NSUIntegerMax; } \

#endif



#undef  __AL_SYNTHESIZE_SINGLETON
#define __AL_SYNTHESIZE_SINGLETON                                                   \
    static NSMutableDictionary *__al_singleton_instance_dict__ = nil;               \
    + (instancetype)sharedInstance {                                                \
        static dispatch_semaphore_t localSem;                                       \
        static dispatch_once_t onceToken;                                           \
        dispatch_once(&onceToken, ^{                                                \
            localSem = dispatch_semaphore_create(1);                                \
        });                                                                         \
                                                                                    \
        NSString *_al_key_ = NSStringFromClass(self);                               \
        id __instance__ = __al_singleton_instance_dict__[_al_key_];                 \
        if (__instance__ == nil) {                                                  \
            dispatch_semaphore_wait(localSem, DISPATCH_TIME_FOREVER);               \
            __instance__ = __al_singleton_instance_dict__[_al_key_];                \
            if (__instance__ == nil) {                                              \
                __instance__ = [[self alloc] init];                                 \
            }                                                                       \
            dispatch_semaphore_signal(localSem);                                    \
        }                                                                           \
        return __instance__;                                                        \
    }                                                                               \
                                                                                    \
    + (instancetype)allocWithZone:(struct _NSZone *)zone {                          \
        static dispatch_semaphore_t localSem;                                       \
        static dispatch_once_t onceToken;                                           \
        dispatch_once(&onceToken, ^{                                                \
            localSem = dispatch_semaphore_create(1);                                \
        });                                                                         \
                                                                                    \
        NSString *_al_key_ = NSStringFromClass(self);                               \
        id __instance__ = __al_singleton_instance_dict__[_al_key_];                 \
        if (__instance__ == nil) {                                                  \
            dispatch_semaphore_wait(localSem, DISPATCH_TIME_FOREVER);               \
            if (__al_singleton_instance_dict__ == nil) {                            \
                __al_singleton_instance_dict__ = [NSMutableDictionary dictionary];  \
            }                                                                       \
            __instance__ = __al_singleton_instance_dict__[_al_key_];                \
            if (__instance__ == nil) {                                              \
                __instance__ = [super allocWithZone:zone];                          \
                if (__instance__) {                                                 \
                    __al_singleton_instance_dict__[_al_key_] = __instance__;        \
                }                                                                   \
            }                                                                       \
            dispatch_semaphore_signal(localSem);                                    \
        }                                                                           \
        return __instance__;                                                        \
    }                                                                               \
                                                                                    \
    + (instancetype)alloc { return [self allocWithZone:NULL]; }                     \
    + (instancetype)new   { return [[self alloc] init]; }                           \
    - (id)copyWithZone:(nullable NSZone *)zone        { return self; }              \
    - (id)mutableCopyWithZone:(nullable NSZone *)zone { return self; }              \
    - (id)copy        { return self; }                                              \
    - (id)mutableCopy { return self; }                                              \

