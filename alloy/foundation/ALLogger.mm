//
//  ALLogger.m
//  patchwork
//
//  Created by Alex Lee on 21/11/2016.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALLogger.h"
#import "ALOCRuntime.h"
#import "NSString+ALHelper.h"
#import "ALMacros.h"
#import "console_logger.hpp"
#import <pthread.h>
#import <chrono>

NS_ASSUME_NONNULL_BEGIN

AL_FORCE_INLINE static NSString *ALLogLevelString(ALLogLevel level) {
    switch (level) {
        case ALLogLevelVerbose:
            return @"-[V]";
        case ALLogLevelInfo:
            return @"-[I]";
        case ALLogLevelWarn:
            return @"-[W]";
        case ALLogLevelError:
            return @"-[E]";

        default:
            return @"";
    }
}

AL_FORCE_INLINE static void ALInnerWriteLog(NSString *file, int line, NSString *func, NSString *tag, ALLogLevel level,
                                            NSString *message, BOOL hasDebugger,
                                            std::chrono::system_clock::time_point now, uint64_t threadID,
                                            BOOL isMainThread) {
    if (hasDebugger) {
        aldb::ConsoleLogger::write(now, threadID, isMainThread, file.UTF8String, line, func.UTF8String, tag.UTF8String,
                                   (aldb::ConsoleLogger::Level) level, message.UTF8String);
    } else {
        NSLog(@"%@ %@ %@", ALLogLevelString(level), func, message);
    }
}

void ALLogImp(NSString *file, int line, NSString *func, NSString *tag, ALLogLevel level, NSString *message,
              BOOL asyncMode) {
    static BOOL hasDebugger = NO;
    static dispatch_once_t onceToken;
    static dispatch_queue_t writeLogQueue;
    dispatch_once(&onceToken, ^{
        hasDebugger   = al_debuggerFound();
        writeLogQueue = dispatch_queue_create("me.alexlee002.alloy.loggerQueue", DISPATCH_QUEUE_SERIAL);
    });

    auto now = std::chrono::system_clock::now();

    __uint64_t threadid;
    pthread_threadid_np(NULL, &threadid);

    bool isMainThread = pthread_main_np() != 0;

    if (asyncMode) {
        dispatch_async(writeLogQueue, ^{
            ALInnerWriteLog(file, line, func, tag, level, message, hasDebugger, now, threadid, isMainThread);
        });
    } else {
        ALInnerWriteLog(file, line, func, tag, level, message, hasDebugger, now, threadid, isMainThread);
    }
}

#define __VariadicArgsImp()                                               \
    if (fmt == nil) {                                                     \
        return;                                                           \
    }                                                                     \
    va_list args;                                                         \
    va_start(args, fmt);                                                  \
    NSString *msg = [[NSString alloc] initWithFormat:fmt arguments:args]; \
    va_end(args);                                                         \
    ALLogImp(file, line, func, tag, level, msg, NO);

void ALLog(NSString *file, int line, NSString *func, NSString *tag, ALLogLevel level, NSString *fmt,
                           ...) {
    __VariadicArgsImp();
}

void ALDebugLog(NSString *file, int line, NSString *func, NSString *tag, ALLogLevel level,
                                NSString *fmt, ...) {
#if DEBUG
    __VariadicArgsImp();
#endif
}

NS_ASSUME_NONNULL_END
