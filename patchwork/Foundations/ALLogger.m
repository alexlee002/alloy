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
                                           NSString *fmt, va_list vaList) {
    static BOOL hasDebugger = NO;
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        hasDebugger = debuggerFound();
        if (hasDebugger) {
            dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.dateFormat = @"hh:mm:ss.SSS";
        }
    });
    
    CFStringRef levelStr = NULL;
    NSString *message = fmt;
    switch (level) {
        case ALLogLevelVerbose:
            levelStr = hasDebugger ? CFSTR("🎐-[V]") : CFSTR("-[V]");
            message = isEmptyString(fmt) ? nil : (hasDebugger ? [@"🎐" stringByAppendingString:fmt] : fmt);
            break;
        case ALLogLevelInfo:
            levelStr = hasDebugger ? CFSTR("✅-[I]") : CFSTR("-[I]");
            message = isEmptyString(fmt) ? nil : (hasDebugger ? [@"✅" stringByAppendingString:fmt] : fmt);
            break;
        case ALLogLevelWarn:
            levelStr = hasDebugger ? CFSTR("⚠️-[W]") : CFSTR("-[W]");
            message = isEmptyString(fmt) ? nil : (hasDebugger ? [@"⚠️" stringByAppendingString:fmt] : fmt);
            break;
        case ALLogLevelError:
            levelStr = hasDebugger ? CFSTR("❌-[E]") : CFSTR("-[E]");
            message = isEmptyString(fmt) ? nil : (hasDebugger ? [@"❌" stringByAppendingString:fmt] : fmt);
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
        CFStringAppendFormat(str, NULL, CFSTR("(%@:%ld) "), [file lastPathComponent], (long)line);
    }
    
    if (!isEmptyString(message)) {
        CFStringAppend(str, (__bridge CFStringRef)message);
    }
    
    NSString *logtext = [[NSString alloc] initWithFormat:(__bridge NSString *)str arguments:vaList];
    
    if (hasDebugger) {
        printf("%s %s\n", [[dateFormatter stringFromDate:[NSDate date]]UTF8String], [logtext UTF8String]);
    } else {
        NSLog(@"%@", logtext);
    }
    CFRelease(str);
}

void ALLog(NSString *file, int line, NSString *func, NSString * tag, ALLogLevel level, NSString *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    _ALLogInternal(file, line, func, tag, level, fmt, args);
    va_end(args);
}

void ALLogDebug(NSString *file, int line, NSString *func, NSString * tag, ALLogLevel level, NSString *fmt, ...) {
#if DEBUG
    va_list args;
    va_start(args, fmt);
    _ALLogInternal(file, line, func, tag, level, fmt, args);
    va_end(args);
#endif
}


void ALLogV1(NSString *file, int line, NSString *func, NSString * tag, ALLogLevel level, NSString *message) {
    ALLog(file, line, func, tag, level, message);
}

void ALLogDebugV1(NSString *file, int line, NSString *func, NSString * tag, ALLogLevel level, NSString *message) {
    ALLogDebug(file, line, func, tag, level, message);
}

NS_ASSUME_NONNULL_END
