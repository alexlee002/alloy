//
//  ALMacros.h
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#ifndef ALUtilitiesHeader_h
#define ALUtilitiesHeader_h

//clang attributes
#define AL_FORCE_INLINE         __inline__ __attribute__((always_inline))
// accept 0 or 1 param with int type. the param value should >= 100
#define AL_CONSTRACTOR(...)     __attribute__((constructor(__VA_ARGS__)))
#define AL_DESTRUCTOR(...)      __attribute__((destructor(__VA_ARGS__)))

#define AL_DEPRECATED(...)      __attribute((deprecated(__VA_ARGS__)))

/**
 * only work for C functions and C params type
 * Example:
 *   void setAge(int age) AL_C_PARAM_ASSERT(age >= 0 && age < 150, "Oh! you're the God!") {
 *       printf("I'm %d years old", age);
 *   }
 *   setAge(-1);    // ✘ compile Error
 *   setAge(151);   // ✘ compile Error
 *   setAge(5);     // ✔
 */
#define AL_C_PARAM_ASSERT(cond, ...) __attribute__((enable_if(cond, __VA_ARGS__)))
// only work for C functions
#define AL_C_OVERLOADABLE   __attribute__((overloadable))

/////////////////////////////////////////////////////////////

//#define AL_FIX_CATEGORY_BUG \


/////////////////////////////////////////////////////////////
#if DEBUG
    #define ALAssert(condition, desc, ...)  NSAssert((condition),  (@"🔥" desc), ##__VA_ARGS__)
    #define ALCAssert(condition, desc, ...) NSCAssert((condition), (@"🔥" desc), ##__VA_ARGS__)
    #define ALParameterAssert(condition)    ALAssert((condition),  @"Invalid parameter not satisfying: %@", @#condition)
    #define ALCParameterAssert(condition)   ALCAssert((condition), @"Invalid parameter not satisfying: %@", @#condition)

#else
    #define ALAssert(condition, desc, ...)  NSAssert((condition),  (desc), ##__VA_ARGS__)
    #define ALCAssert(condition, desc, ...) NSCAssert((condition), (desc), ##__VA_ARGS__)
    #define ALParameterAssert(condition)    NSParameterAssert((condition))
#define ALCParameterAssert(condition) NSCParameterAssert((condition))

#endif

#define AL_VOID (void)0

#import <objc/message.h>
#define al_safeInvokeSelector(returnType, obj, sel)                                         \
    ({                                                                                      \
        returnType result = 0x00;                                                           \
        if ([(id)(obj) respondsToSelector:(sel)]) {                                         \
            result = (returnType)((id(*)(id, SEL))(void *) objc_msgSend)((id)(obj), (sel)); \
        }                                                                                   \
        result;                                                                             \
    })

/**
 * example:
    - (void)Foo:(id)arg {
        al_guard_or_return(arg != nil, AL_VOID);
        // do your job here
    }
 */
#define al_guard_or_return(condition, elseReturn)           \
    if (!(condition)) {                                     \
        ALAssert(NO, @"Not satisfying: %@", @#condition);   \
        return (elseReturn);                                \
    }

#define al_guard_or_return1(condition, elseReturn, desc, ...)   \
    if (!(condition)) {                                         \
        ALAssert(NO, desc, ##__VA_ARGS__);                      \
        return (elseReturn);                                    \
    }

/**
 * example:
    void foo(int arg) {
        al_c_guard_or_return(arg > 0, AL_VOID);
        // do your job here
    }
 */
#define al_c_guard_or_return(condition, elseReturn)         \
    if (!(condition)) {                                     \
        ALCAssert(NO, @"Not satisfying: %@", @#condition);  \
        return (elseReturn);                                \
    }


/////////////////////////////////////////////////////////////
#if TARGET_OS_IPHONE
#   define PROP_ATOMIC_DEF nonatomic
#else
#   define PROP_ATOMIC_DEF atomic
#endif

// local static lock
#define al_static_gcd_semaphore_def(sem_name, sem_val)  \
    static dispatch_semaphore_t sem_name;               \
    static dispatch_once_t once_##sem_name;             \
    dispatch_once(&once_##sem_name, ^{                  \
        sem_name = dispatch_semaphore_create(sem_val);  \
    });


// cast "obj" to "type", or return nil if failed
#define ALCastToTypeOrNil(obj, type) ([(obj) isKindOfClass:[type class]] ? (type *)(obj) : nil)

// verify and invoke block
#define ALSafeInvokeBlock(block, ...)   \
    if ((block) != nil) {               \
        (block)( __VA_ARGS__ );         \
    }

#define ALSafeInvokeBlockInMainThread(block, ...)       \
    if ((block) != nil) {                               \
        dispatch_async(dispatch_get_main_queue(), ^{    \
            ALSafeInvokeBlock((block), __VA_ARGS__ );   \
        });                                             \
    }



//#undef metamacro_concat
#define al_metamacro_concat(A, B)   al_metamacro_concat_(A, B)
#define al_metamacro_concat_(A, B)  A ## B

//#undef weakify
#define al_weakify(var) __weak __typeof__(var) al_metamacro_concat(_weak_, var) = (var);

//#undef unsafeify
#define al_unsafeify(var) __unsafe_unretained __typeof__(var) al_metamacro_concat(_weak_, var) = (var);

//#undef strongify
#define al_strongify(var) __strong __typeof__(var) var = al_metamacro_concat(_weak_, var);

/**
 * Usage: keypath(object.property)
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
#define al_keypath(PATH) @(((void)(NO && ((void)PATH, NO)), (strchr(#PATH, '.') == NULL ? #PATH : strchr(#PATH, '.') + 1)))

#define al_keypathForClass(CLASS, PATH) @(((void)(NO && ((void)[[CLASS alloc] init].PATH, NO)), # PATH))


/////////////////////////////////////////////////////////////
// CheckMemoryLeak
#if DEBUG
#define ALTrackMemoryLeak(willReleaseObject) __weak typeof(willReleaseObject) _weak_##willReleaseObject = willReleaseObject;

#define ALCheckMemoryLeak(willReleaseObject)   \
    do {                                        \
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),      \
               dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{          \
                    if (_weak_##willReleaseObject != nil) {                                  \
                        ALLogWarn(@"\n************************************************"      \
                                  @"\n* Memory leaks may have occurred: %@ is not dealloced." \
                                  @"\n************************************************",     \
                                  [_weak_##willReleaseObject debugDescription]);             \
                    }                           \
               });                              \
    } while(0)
#else
#define ALTrackMemoryLeak(willReleaseObject) do{}while(0)
#define ALCheckMemoryLeak(willReleaseObject) do{}while(0)
#endif


//-Warc-performSelector-leaks
#define _AL_PRAGMA(msg) _Pragma(#msg)
#define ALIgnoreClangDiagnostic(SUPPRESSED, wrappedStatements)  \
    _Pragma("clang diagnostic push")                            \
    _AL_PRAGMA(clang diagnostic ignored SUPPRESSED)             \
    wrappedStatements                                           \
    _Pragma("clang diagnostic pop")


////////////////////////////////////////////////////////////////

//#define __ALNAME_PREPEND(a,b) al_metamacro_concat(a,b)

#ifdef  AL_SDK_NAME_PREFIX
    #define AL_NAME_PREPEND(x) al_metamacro_concat(AL_SDK_NAME_PREFIX, x)
#else  // RKL_PREPEND_TO_METHODS
    #define AL_NAME_PREPEND(x) x
#endif // RKL_PREPEND_TO_METHODS


#endif /* ALUtilitiesHeader_h */

