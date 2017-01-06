//
//  ALLogger.m
//  patchwork
//
//  Created by Alex Lee on 21/11/2016.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALLogger.h"
#import "ALOCRuntime.h"
#import "NSString+Helper.h"
#import <pthread.h>

NS_ASSUME_NONNULL_BEGIN

AL_FORCE_INLINE void ALLogImp(NSString *file, int line, NSString *func, NSString *tag, ALLogLevel level,
                              NSString *message) {
    static BOOL hasDebugger = NO;
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    static dispatch_queue_t writeLogQueue;
    dispatch_once(&onceToken, ^{
        hasDebugger = debuggerFound();
        if (hasDebugger) {
            dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.dateFormat = @"hh:mm:ss.SSS";
        }
        writeLogQueue = dispatch_queue_create("me.alexlee002.patchwork.loggerQueue", DISPATCH_QUEUE_SERIAL);
    });
    
    NSDate *logtime = [NSDate date];
    __uint64_t threadID;
    pthread_threadid_np(NULL, &threadID);
    BOOL isMainThread = [NSThread isMainThread];
    
    dispatch_async(writeLogQueue, ^{
        @autoreleasepool {
            CFStringRef levelStr = NULL;
            NSString *logmsg     = message;
            switch (level) {
                case ALLogLevelVerbose:
                    levelStr = hasDebugger ? CFSTR("🎐-[V]") : CFSTR("-[V]");
                    logmsg   = isEmptyString(message) ? nil : (hasDebugger ? [@"🎐" stringByAppendingString:message] : message);
                    break;
                case ALLogLevelInfo:
                    levelStr = hasDebugger ? CFSTR("✅-[I]") : CFSTR("-[I]");
                    logmsg   = isEmptyString(message) ? nil : (hasDebugger ? [@"✅" stringByAppendingString:message] : message);
                    break;
                case ALLogLevelWarn:
                    levelStr = hasDebugger ? CFSTR("⚠️-[W]") : CFSTR("-[W]");
                    logmsg   = isEmptyString(message) ? nil : (hasDebugger ? [@"⚠️" stringByAppendingString:message] : message);
                    break;
                case ALLogLevelError:
                    levelStr = hasDebugger ? CFSTR("❌-[E]") : CFSTR("-[E]");
                    logmsg   = isEmptyString(message) ? nil : (hasDebugger ? [@"❌" stringByAppendingString:message] : message);
                    break;
                    
                default:
                    break;
            }
            
            CFMutableStringRef str = CFStringCreateMutable(NULL, 0);
            
            if (levelStr != NULL) {
                CFStringAppend(str, levelStr);
                CFStringAppend(str, CFSTR(" "));
            }
            
            CFStringAppendFormat(str, NULL, CFSTR("[%llu%s] "), threadID, isMainThread ? " (main)" : "");
            
            if (!isEmptyString(tag)) {
                CFStringAppendFormat(str, NULL, hasDebugger ? CFSTR("⚓[%@] ") : CFSTR("[%@] "), tag);
            }
            
            if (!isEmptyString(func)) {
                CFStringAppendFormat(str, NULL, CFSTR("%@ "), func);
            }
            if (!isEmptyString(file)) {
                CFStringAppendFormat(str, NULL, CFSTR("(%@:%ld) "), [file lastPathComponent], (long) line);
            }
            
            if (!isEmptyString(logmsg)) {
                CFStringAppend(str, (__bridge CFStringRef) logmsg);
            }
            
            if (hasDebugger) {
                printf("%s %s\n", [[dateFormatter stringFromDate:logtime] UTF8String],
                       [(__bridge NSString *)str UTF8String]);
            } else {
                NSLog(@"%@", (__bridge NSString *)str);
            }
            
            CFRelease(str);
        }
    });
}

#define __VariadicArgsImp()                                               \
    if (fmt == nil) {                                                     \
        return;                                                           \
    }                                                                     \
    va_list args;                                                         \
    va_start(args, fmt);                                                  \
    NSString *msg = [[NSString alloc] initWithFormat:fmt arguments:args]; \
    va_end(args);                                                         \
    ALLogImp(file, line, func, tag, level, msg);

void ALLog(NSString *file, int line, NSString *func, NSString *tag, ALLogLevel level, NSString *fmt,
                           ...) {
    __VariadicArgsImp();
}

void ALLogDebug(NSString *file, int line, NSString *func, NSString *tag, ALLogLevel level,
                                NSString *fmt, ...) {
#if DEBUG
    __VariadicArgsImp();
#endif
}

NS_ASSUME_NONNULL_END
