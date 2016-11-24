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

extern void ALLog(NSString *file, int line, NSString *func, NSString * tag, ALLogLevel level, NSString *fmt, ...);

#define __ALLog(level, fmt, ...)                                \
    ALLog(  (__bridge NSString *)CFSTR(__FILE__),               \
            __LINE__,                                           \
            [NSString stringWithUTF8String:__PRETTY_FUNCTION__],\
            nil,                                                \
            level,                                              \
            fmt,                                                \
            ##__VA_ARGS__)


#define ALLogVerbose(fmt, ...)  __ALLog(ALLogLevelVerbose, fmt, ##__VA_ARGS__)
#define ALLogInfo(fmt, ...)     __ALLog(ALLogLevelInfo,    fmt, ##__VA_ARGS__)
#define ALLogWarn(fmt, ...)     __ALLog(ALLogLevelWarn,    fmt, ##__VA_ARGS__)
#define ALLogError(fmt, ...)    __ALLog(ALLogLevelError,   fmt, ##__VA_ARGS__)

