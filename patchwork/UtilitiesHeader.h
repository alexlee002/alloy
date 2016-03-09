//
//  UtilitiesHeader.h
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#ifndef UtilitiesHeader_h
#define UtilitiesHeader_h

#define FORCE_INLINE __inline__ __attribute__((always_inline))

#if TARGET_OS_IPHONE
#   define PROP_ATOMIC_DEF nonatomic
#else
#   define PROP_ATOMIC_DEF
#endif




//日志相关
// 如果安装了 Xcode 的 MCLog插件， 支持彩色日志输出和日志分级， 如果没有安装此插件， 则把下边的宏定义注释即可
#ifndef EnableColorLog
#define EnableColorLog 1
#endif

// clang-format off
#define __PRETTY_FILE_NAME (__FILE__ ? [[NSString stringWithUTF8String:__FILE__] lastPathComponent] : @"")
#if DEBUG
#   if EnableColorLog
#       define __ALLog(LEVEL, fmt, ...)  \
            NSLog((@"-" LEVEL @"\033[2;3;4m %s (%@:%d)\033[22;23;24m " fmt @"\033[0m"), __PRETTY_FUNCTION__, __PRETTY_FILE_NAME, \
                    __LINE__, ##__VA_ARGS__)
#   else
#       define __ALLog(LEVEL, fmt, ...) \
            NSLog((@"-" LEVEL @" %s (%@:%d) " fmt), __PRETTY_FUNCTION__, __PRETTY_FILE_NAME, __LINE__, ##__VA_ARGS__)
#   endif
#else
#   define __ALLog(LEVEL, fmt, ...) do {} while (0)
#endif

#define ALLogVerbose(fmt, ...)  __ALLog(@"[VERBOSE]",   fmt, ##__VA_ARGS__)
#define ALLogInfo(fmt, ...)     __ALLog(@"[INFO]",      fmt, ##__VA_ARGS__)
#define ALLogWarn(fmt, ...)     __ALLog(@"[WARN]",      fmt, ##__VA_ARGS__)
#define ALLogError(fmt, ...)    __ALLog(@"[ERROR]",     fmt, ##__VA_ARGS__)
// clang-format on

#define IgnorePerformSelectorLeakWarningInARC(statments) \
do { \
    _Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
    statments \
    _Pragma("clang diagnostic pop") \
} while (0)


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

//检查版本号
#define IOS_VERSION_NOT_BEFORE(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define IOS_VERSION_EQUAL_TO(v)    ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)



#endif /* UtilitiesHeader_h */
