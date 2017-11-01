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

// weak singleton
#if __has_feature(objc_arc)
    #undef AL_AS_WEAK_SINGLETON
    #define AL_AS_WEAK_SINGLETON    + (instancetype)sharedInstance;

    #undef  AL_SYNTHESIZE_WEAK_SINGLETON
    #define AL_SYNTHESIZE_WEAK_SINGLETON(CLS)                       \
        static __weak CLS *__AL_INSTANCE_FOR_CLASS(CLS) = nil;      \
        __AL_SYNTHESIZE_SINGLETON(CLS)                              \

#endif

////////////////////////////////////

// define
#undef  AL_AS_SINGLETON
#define AL_AS_SINGLETON                 \
        + (instancetype)sharedInstance; \
        + (void)al_destroyInstance;     \
        - (void)al_destroyInstance;

// synthesize
#undef  AL_SYNTHESIZE_SINGLETON
#if __has_feature(objc_arc)
    #define AL_SYNTHESIZE_SINGLETON(CLS)                \
    static CLS *__AL_INSTANCE_FOR_CLASS(CLS) = nil;     \
    __AL_SYNTHESIZE_SINGLETON(CLS)                      \

#else
    #define AL_SYNTHESIZE_SINGLETON(CLS)                    \
        static CLS *__AL_INSTANCE_FOR_CLASS(CLS) = nil;     \
        __AL_SYNTHESIZE_SINGLETON(CLS)                      \
                                                            \
        - (instancetype)retain {  return self; }            \
        - (oneway void)release {}                           \
        - (instancetype)autorelease { return self; }        \
        - (NSUInteger)retainCount { return NSUIntegerMax; } \

#endif

#undef AL_SINGLETON_INITIALIZED_CHECK
#define AL_SINGLETON_INITIALIZED_CHECK(CLS)                     \
    if (__AL_INSTANCE_INIT_FLAG_FOR_CLASS(CLS)) { return; }     \
    __AL_INSTANCE_INIT_FLAG_FOR_CLASS(CLS) = YES;               \

//////////////////////////////////////////////////////////////////////
// internal macros

#undef __AL_MACRO_CONCAT_
#define __AL_MACRO_CONCAT_(a, b)    a ## b
#undef __AL_MACRO_CONCAT
#define __AL_MACRO_CONCAT(a, b) __AL_MACRO_CONCAT_(a, b)

#undef __AL_INSTANCE_FOR_CLASS
#define __AL_INSTANCE_FOR_CLASS(cls)    __AL_MACRO_CONCAT(__al_singleton_instance_, cls)

#undef __AL_INSTANCE_INIT_FLAG_FOR_CLASS
#define __AL_INSTANCE_INIT_FLAG_FOR_CLASS(cls) __AL_MACRO_CONCAT(__AL_INSTANCE_FOR_CLASS(cls), _inited)


#undef  __AL_SYNTHESIZE_SINGLETON
#define __AL_SYNTHESIZE_SINGLETON(CLS)                                          \
    static BOOL __AL_INSTANCE_INIT_FLAG_FOR_CLASS(CLS) = NO;                    \
    + (instancetype)sharedInstance {                                            \
        CLS *strongRef = __AL_INSTANCE_FOR_CLASS(CLS);                          \
        if (strongRef == nil) {                                                 \
            __AL_INSTANCE_INIT_FLAG_FOR_CLASS(CLS) = NO;                        \
            strongRef = [[self alloc] init];                                    \
            __AL_INSTANCE_FOR_CLASS(CLS) = strongRef;                           \
        }                                                                       \
        return strongRef;                                                       \
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
        CLS *strongRef = __AL_INSTANCE_FOR_CLASS(CLS);                          \
        if (strongRef == nil || [strongRef class] != [self class]) {            \
            strongRef = [super allocWithZone:zone];                             \
            __AL_INSTANCE_FOR_CLASS(CLS) = strongRef;                           \
        }                                                                       \
        dispatch_semaphore_signal(lock);                                        \
                                                                                \
        return strongRef;                                                       \
    }                                                                           \
                                                                                \
    + (instancetype)alloc { return [self allocWithZone:NULL]; }                 \
    + (instancetype)new   { return [[self alloc] init]; }                       \
    - (id)copyWithZone:(nullable NSZone *)zone        { return self; }          \
    - (id)mutableCopyWithZone:(nullable NSZone *)zone { return self; }          \
    - (id)copy        { return self; }                                          \
    - (id)mutableCopy { return self; }                                          \
    + (void)al_destroyInstance {                                                \
        ALLogWarn(@"❗❗❗Singleton instance [%@:%p] will be destroyed!", self, __AL_INSTANCE_FOR_CLASS(CLS));     \
        __AL_INSTANCE_FOR_CLASS(CLS) = nil;                                     \
        __AL_INSTANCE_INIT_FLAG_FOR_CLASS(CLS) = NO;                            \
    }                                                                           \
    - (void)al_destroyInstance { [self.class al_destroyInstance]; };            \

