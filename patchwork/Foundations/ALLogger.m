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

NS_ASSUME_NONNULL_BEGIN

AL_FORCE_INLINE static void _ALLogInternal(NSString *file, int line, NSString *func, NSString *tag, ALLogLevel level,
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
                printf("%s %s\n", [[dateFormatter stringFromDate:[NSDate date]] UTF8String],
                       [(__bridge NSString *)str UTF8String]);
            } else {
                NSLog(@"%@", (__bridge NSString *)str);
            }
            
            CFRelease(str);
        }
    });
}

void ALLog(NSString *file, int line, NSString *func, NSString * tag, ALLogLevel level, NSString *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    NSString *msg = [[NSString alloc] initWithFormat:fmt arguments:args];
    va_end(args);
    _ALLogInternal(file, line, func, tag, level, msg);
}

void ALLogDebug(NSString *file, int line, NSString *func, NSString * tag, ALLogLevel level, NSString *fmt, ...) {
#if DEBUG
    va_list args;
    va_start(args, fmt);
    NSString *msg = [[NSString alloc] initWithFormat:fmt arguments:args];
    va_end(args);
    _ALLogInternal(file, line, func, tag, level, msg);
#endif
}


void ALLogV1(NSString *file, int line, NSString *func, NSString * tag, ALLogLevel level, NSString *message) {
    ALLog(file, line, func, tag, level, message);
}

void ALLogDebugV1(NSString *file, int line, NSString *func, NSString * tag, ALLogLevel level, NSString *message) {
    ALLogDebug(file, line, func, tag, level, message);
}

NS_ASSUME_NONNULL_END
