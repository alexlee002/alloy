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

void ALLog(NSString *file, int line, NSString *func, NSString * tag, ALLogLevel level, NSString *fmt, ...) {
#if DEBUG
    static BOOL hasDebugger = NO;
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        hasDebugger = debuggerFound();
        if (hasDebugger) {
            dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.dateFormat = @"yyyy-MM-dd hh:mm:ss.SSS";
        }
    });
    
    CFStringRef levelStr = NULL;
    NSString *message = nil;
    switch (level) {
        case ALLogLevelVerbose:
            levelStr = CFSTR("-[VERBOSE]");
            message = isEmptyString(fmt) ? nil : (hasDebugger ? [@"🐔" stringByAppendingString:fmt] : fmt);
            break;
        case ALLogLevelInfo:
            levelStr = CFSTR("-[INFO]");
            message = isEmptyString(fmt) ? nil : (hasDebugger ? [@"✅" stringByAppendingString:fmt] : fmt);
            break;
        case ALLogLevelWarn:
            levelStr = CFSTR("-[WARN]");
            message = isEmptyString(fmt) ? nil : (hasDebugger ? [@"⚠️" stringByAppendingString:fmt] : fmt);
            break;
        case ALLogLevelError:
            levelStr = CFSTR("-[ERROR]");
            message = isEmptyString(fmt) ? nil : (hasDebugger ? [@"❌" stringByAppendingString:fmt] : fmt);
            break;
            
        default:
            break;
    }
    
    CFMutableStringRef str = CFStringCreateMutable(NULL, 0);
    if (hasDebugger) {
        CFStringAppend(str, (__bridge CFStringRef)[dateFormatter stringFromDate:[NSDate date]]);
        CFStringAppend(str, CFSTR(" "));
    }
   
    if (levelStr != NULL) {
        CFStringAppend(str, levelStr);
        CFStringAppend(str, CFSTR(" "));
    }
    
    if (!isEmptyString(tag)) {
        CFStringAppendFormat(str, NULL, CFSTR("[%@]"), tag);
        CFStringAppend(str, CFSTR(" "));
    }
    
    BOOL located = NO;
    if (!isEmptyString(func)) {
        located = YES;
        CFStringAppendFormat(str, NULL, CFSTR("📍%@"), func);
    }
    if (!isEmptyString(file)) {
        if (!located) {
            CFStringAppend(str, CFSTR("📍"));
            located = YES;
        }
        CFStringAppendFormat(str, NULL, CFSTR(" (%@:%ld)"), [file lastPathComponent], (long)line);
    }
    if (located) {
        CFStringAppend(str, CFSTR(" "));
    }
    
    if (!isEmptyString(fmt)) {
        //CFStringAppendFormat(str, NULL, CFSTR("ℹ️%@"), fmt);
        CFStringAppend(str, (__bridge CFStringRef)message);
    }
    
    va_list args;
    va_start(args, fmt);
    NSString *logtext = [[NSString alloc] initWithFormat:(__bridge NSString *)str arguments:args];
    va_end(args);
    
    if (hasDebugger) {
        printf("%s\n", [logtext UTF8String]);
    } else {
        NSLog(@"%@", logtext);
    }
    CFRelease(str);
    
#endif
}


NS_ASSUME_NONNULL_END
