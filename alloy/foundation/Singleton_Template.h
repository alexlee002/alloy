//
//  Singleton_Template.h
//  patchwork
//
//  Created by Alex Lee on 3/11/15.
//  Copyright © 2015 Alex Lee. All rights reserved.
//


/**
 * A template code for define a singleton class.
 * Example:
    <code>
    // .h file
    @interface SingletionTest : NSObject
    AS_SINGLETON
    @end
 
    // .m file
    @implementation SingletionTest
    SYNTHESIZE_SINGLETON(SingletionTest)
 
    // implement -init method if needed, eg:
    // - (instancetype)init {
    //      SINGLETON_INITIALIZED_CHECK(SingletionTest);  // optional
    //      self = [super init];
    //      ...
    //      return self;
    // }
    @end
 
    // usage:
    SingletionTest *singleton = [SingletionTest sharedInstance];
    // or: SingletionTest *singleton = [[SingletionTest alloc] init];
    // or: SingletionTest *singleton = [SingletionTest new];
    </code>
 */

#import "ALLogger.h"
// define
#undef  AS_SINGLETON
#define AS_SINGLETON                    \
        + (instancetype)sharedInstance; \
        + (void)al_destroyInstance;     \
        - (void)al_destroyInstance;

// synthesize
#undef  SYNTHESIZE_SINGLETON
#if __has_feature(objc_arc)
    #define SYNTHESIZE_SINGLETON(CLS)  __AL_SYNTHESIZE_SINGLETON(CLS)
#else
    #define SYNTHESIZE_SINGLETON(CLS)                       \
        __AL_SYNTHESIZE_SINGLETON(CLS)                      \
                                                            \
        - (instancetype)retain {  return self; }            \
        - (oneway void)release {}                           \
        - (instancetype)autorelease { return self; }        \
        - (NSUInteger)retainCount { return NSUIntegerMax; } \

#endif

#undef SINGLETON_INITIALIZED_CHECK
#define SINGLETON_INITIALIZED_CHECK(CLS)                    \
    if (__al_singleton_instance_##CLS_inited) { return; }   \
    __al_singleton_instance_##CLS_inited = YES;             \

// internal macros
#undef  __AL_SYNTHESIZE_SINGLETON
#define __AL_SYNTHESIZE_SINGLETON(CLS)                                          \
    static CLS *__al_singleton_instance_##CLS = nil;                            \
    static BOOL __al_singleton_instance_##CLS_inited = NO;                      \
    + (instancetype)sharedInstance {                                            \
        if (__al_singleton_instance_##CLS == nil) {                             \
            __al_singleton_instance_##CLS = [[self alloc] init];                \
        }                                                                       \
        return __al_singleton_instance_##CLS;                                   \
    }                                                                           \
                                                                                \
    + (instancetype)allocWithZone:(struct _NSZone *)zone {                      \
        static dispatch_semaphore_t lock;                                       \
        static dispatch_once_t onceToken;                                       \
        dispatch_once(&onceToken, ^{                                            \
            lock = dispatch_semaphore_create(1);                                \
        });                                                                     \
                                                                                \
        dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);                   \
        if (__al_singleton_instance_##CLS == nil || __al_singleton_instance_##CLS.class != self.class) {  \
            __al_singleton_instance_##CLS = [super allocWithZone:zone];         \
        }                                                                       \
        dispatch_semaphore_signal(lock);                                        \
                                                                                \
        return __al_singleton_instance_##CLS;                                   \
    }                                                                           \
                                                                                \
    + (instancetype)alloc { return [self allocWithZone:NULL]; }                 \
    + (instancetype)new   { return [[self alloc] init]; }                       \
    - (id)copyWithZone:(nullable NSZone *)zone        { return self; }          \
    - (id)mutableCopyWithZone:(nullable NSZone *)zone { return self; }          \
    - (id)copy        { return self; }                                          \
    - (id)mutableCopy { return self; }                                          \
    + (void)al_destroyInstance {                                                \
        ALLogWarn(@"❗❗❗Singleton instance [%@:%p] will be destroyed!", self, __al_singleton_instance_##CLS);     \
        __al_singleton_instance_##CLS = nil;                                    \
        __al_singleton_instance_##CLS_inited = NO;                              \
    }                                                                           \
    - (void)al_destroyInstance { [self.class al_destroyInstance]; };            \

