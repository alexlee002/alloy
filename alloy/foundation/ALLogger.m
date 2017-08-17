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
#import <pthread.h>
#import "ALUtilitiesHeader.h"

NS_ASSUME_NONNULL_BEGIN

AL_FORCE_INLINE static void ALInnerWriteLog(NSString *file, int line, NSString *func, NSString *tag, ALLogLevel level,
                                            NSString *message, BOOL hasDebugger, NSString *timeString,
                                            uint64_t threadID, BOOL isMainThread) {
    CFStringRef levelStr = NULL;
    NSString *logmsg     = message;
    if (!al_isEmptyString(message) && hasDebugger) {
        logmsg = [@"👉" stringByAppendingString:message];
    }
    
    switch (level) {
        case ALLogLevelVerbose:
            levelStr = hasDebugger ? CFSTR("👾-[V]") : CFSTR("-[V]");
            break;
        case ALLogLevelInfo:
            levelStr = hasDebugger ? CFSTR("✅-[I]") : CFSTR("-[I]");
            break;
        case ALLogLevelWarn:
            levelStr = hasDebugger ? CFSTR("⚠️-[W]") : CFSTR("-[W]");
            break;
        case ALLogLevelError:
            levelStr = hasDebugger ? CFSTR("❌-[E]") : CFSTR("-[E]");
            break;
            
        default:
            break;
    }
    
    CFMutableStringRef str = CFStringCreateMutable(NULL, 0);
    
    if (levelStr != NULL) {
        CFStringAppend(str, levelStr);
        CFStringAppend(str, CFSTR(" "));
    }
    
    CFStringAppendFormat(str, NULL, CFSTR("[%llu%s] "), threadID, isMainThread ? "(main)" : "");
    
    if (!al_isEmptyString(tag)) {
        CFStringAppendFormat(str, NULL, hasDebugger ? CFSTR("[%@] ") : CFSTR("[%@] "), tag);
    }
    
    if (!al_isEmptyString(func)) {
        CFStringAppendFormat(str, NULL, CFSTR("%@ "), func);
    }
    if (!al_isEmptyString(file)) {
        CFStringAppendFormat(str, NULL, CFSTR("(%@:%ld) "), [file lastPathComponent], (long) line);
    }
    
    if (!al_isEmptyString(logmsg)) {
        CFStringAppend(str, (__bridge CFStringRef) logmsg);
    }
    
    if (hasDebugger) {
        printf("%s %s\n", [timeString UTF8String], [(__bridge NSString *)str UTF8String]);
    } else {
        NSLog(@"%@", (__bridge NSString *)str);
    }
    
    CFRelease(str);
}

void ALLogImp(NSString *file, int line, NSString *func, NSString *tag, ALLogLevel level,
                              NSString *message, BOOL asyncMode) {
    static BOOL hasDebugger = NO;
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    static dispatch_queue_t writeLogQueue;
    dispatch_once(&onceToken, ^{
        hasDebugger = al_debuggerFound();
        if (hasDebugger) {
            dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.dateFormat = @"hh:mm:ss.SSS";
        }
        writeLogQueue = dispatch_queue_create("me.alexlee002.patchwork.loggerQueue", DISPATCH_QUEUE_SERIAL);
    });
    
    
    __uint64_t threadID;
    pthread_threadid_np(NULL, &threadID);
    BOOL isMainThread = pthread_main_np() != 0;
    NSString *timestr = [dateFormatter stringFromDate:[NSDate date]];
    
    if (asyncMode) {
        dispatch_async(writeLogQueue, ^{
            ALInnerWriteLog(file, line, func, tag, level, message, hasDebugger, timestr, threadID, isMainThread);
        });
    } else {
        ALInnerWriteLog(file, line, func, tag, level, message, hasDebugger, timestr, threadID, isMainThread);
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
