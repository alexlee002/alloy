//
//  UtilitiesHeader.h
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#ifndef UtilitiesHeader_h
#define UtilitiesHeader_h

// maximum time (seconds) a database queue operation (eg: inDatabase:) can execute.
#define MAX_DB_BLOCK_EXECUTE_SEC   5

#define FORCE_INLINE __inline__ __attribute__((always_inline))

#if TARGET_OS_IPHONE
#   define PROP_ATOMIC_DEF nonatomic
#else
#   define PROP_ATOMIC_DEF atomic
#endif

// local static lock
#define LocalDispatchSemaphoreLock_Wait()    \
    static dispatch_semaphore_t lock;        \
    static dispatch_once_t onceToken;        \
    dispatch_once(&onceToken, ^{             \
        lock = dispatch_semaphore_create(1); \
    });                                      \
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER)

#define LocalDispatchSemaphoreLock_Signal() dispatch_semaphore_signal(lock)

// cast "obj" to "type", or return nil if failed
#define castToTypeOrNil(obj, type) ([(obj) isKindOfClass:[type class]] ? (type *)(obj) : nil)

// verify and invoke block
#define safeInvokeBlock(block, ...) \
    if ((block) != nil) {           \
        (block)( __VA_ARGS__ );     \
    }

#define safeInvokeBlockInMainThread(block, ...)         \
    if ((block) != nil) {                               \
        dispatch_async(dispatch_get_main_queue(), ^{    \
            (block)( __VA_ARGS__ );                     \
        });                                             \
    }

// CheckMemoryLeak
#if DEBUG
#define TrackMemoryLeak(willReleaseObject) __weak typeof(willReleaseObject) _weak_##willReleaseObject = willReleaseObject;

#define CheckMemoryLeak(willReleaseObject)  \
    do {                                    \
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),      \
               dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{          \
                    if (_weak_##willReleaseObject != nil) {                                  \
                        ALLogWarn(@"\n************************************************"      \
                                  @"\n* Memory leaks may have occurred: %@ is not dealloced." \
                                  @"\n************************************************",     \
                                  [_weak_##willReleaseObject debugDescription]);             \
                    }                       \
               });                          \
    } while(0)
#else
#define TrackMemoryLeak(willReleaseObject) do{}while(0)
#define CheckMemoryLeak(willReleaseObject) do{}while(0)
#endif


//-Warc-performSelector-leaks
#define _AL_PRAGMA(msg) _Pragma(#msg)
#define IgnoreClangDiagnostic(SUPPRESSED, wrappedStatements) \
    _Pragma("clang diagnostic push") \
    _AL_PRAGMA(clang diagnostic ignored SUPPRESSED) \
    wrappedStatements \
    _Pragma("clang diagnostic pop")


//#undef metamacro_concat
#define metamacro_concat(A, B) A ## B

//#undef weakify
#define weakify(var) __weak __typeof__(var) metamacro_concat(_weak_, var) = (var);

//#undef unsafeify
#define unsafeify(var) __unsafe_unretained __typeof__(var) metamacro_concat(_weak_, var) = (var);

//#undef strongify
#define strongify(var) __strong __typeof__(var) var = metamacro_concat(_weak_, var);

/**
 * Usage: @keypath(object.property)
 *
 * IMPORTANT: you must really know what param you pass to this macro. NO ZUO NO DIE :)
 *
 * split key path from an object
 * eg:  keypath(a)      return "a"
 *      keypath(a.b)    return "b"
 *      keypath(a.b.c)  return "b.c"
 *      ...             ...
 *
 * @param   path
 * @return  key path
 */
#define keypath(PATH) @(((void)(NO && ((void)PATH, NO)), (strchr(#PATH, '.') == NULL ? #PATH : strchr(#PATH, '.') + 1)))

#define keypathForClass(CLASS, PATH) @(((void)(NO && ((void)[[CLASS alloc] init].PATH, NO)), # PATH))

////检查版本号
//#define IOS_VERSION_NOT_BEFORE(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
//#define IOS_VERSION_EQUAL_TO(v)    ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)



#endif /* UtilitiesHeader_h */
