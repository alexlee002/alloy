//
//  ALLogger.h
//  patchwork
//
//  Created by Alex Lee on 21/11/2016.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, ALLogLevel) {
    ALLogLevelVerbose   = 0,
    ALLogLevelInfo,
    ALLogLevelWarn,
    ALLogLevelError,
};

//always log, much like NSLog
extern void ALLog(NSString *file, int line, NSString *func, NSString * tag, ALLogLevel level, NSString *fmt, ...);

// only log in DEBUG model
extern void ALLogDebug(NSString *file, int line, NSString *func, NSString * tag, ALLogLevel level, NSString *fmt, ...);

// for swift, can not call variadic functions in swift.
extern void ALLogV1(NSString *file, int line, NSString *func, NSString * tag, ALLogLevel level, NSString *message);
extern void ALLogDebugV1(NSString *file, int line, NSString *func, NSString * tag, ALLogLevel level, NSString *message);


#if DEBUG
#define __ALLog(level, tag, fmt, ...)                           \
    ALLog(  (__bridge NSString *)CFSTR(__FILE__),               \
            __LINE__,                                           \
            [NSString stringWithUTF8String:__PRETTY_FUNCTION__],\
            tag,                                                \
            level,                                              \
            fmt,                                                \
            ##__VA_ARGS__)
#else
    #define __ALLog(level, tag, fmt, ...) do{}while(0)
#endif


#define ALLogVerbose(fmt, ...)  __ALLog(ALLogLevelVerbose, nil, fmt, ##__VA_ARGS__)
#define ALLogInfo(fmt, ...)     __ALLog(ALLogLevelInfo,    nil, fmt, ##__VA_ARGS__)
#define ALLogWarn(fmt, ...)     __ALLog(ALLogLevelWarn,    nil, fmt, ##__VA_ARGS__)
#define ALLogError(fmt, ...)    __ALLog(ALLogLevelError,   nil, fmt, ##__VA_ARGS__)

#define ALLogVerboseTag(tag, fmt, ...)  __ALLog(ALLogLevelVerbose, tag, fmt, ##__VA_ARGS__)
#define ALLogInfoTag(tag, fmt, ...)     __ALLog(ALLogLevelInfo,    tag, fmt, ##__VA_ARGS__)
#define ALLogWarnTag(tag, fmt, ...)     __ALLog(ALLogLevelWarn,    tag, fmt, ##__VA_ARGS__)
#define ALLogErrorTag(tag, fmt, ...)    __ALLog(ALLogLevelError,   tag, fmt, ##__VA_ARGS__)

