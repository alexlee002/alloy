//
//  StringHelper.m
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "NSString+Helper.h"

NS_ASSUME_NONNULL_BEGIN

FORCE_INLINE id wrapNil(id _Nullable obj) {
    return obj == nil ? NSNull.null : obj;
}

FORCE_INLINE id _Nullable unwrapNil(id _Nullable obj) {
    return obj == NSNull.null ? nil : obj;
}

FORCE_INLINE NSString *stringOrEmpty(NSString *_Nullable string) {
    NSString *tmp = [string stringify];
    return tmp == nil ? @"" : tmp;
}

FORCE_INLINE BOOL isEmptyString(NSString *_Nullable string) {
    if ([string isKindOfClass:[NSString class]]) {
        if (string.length == 0) {
            return YES;
        }
        if ([string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0) {
            return YES;
        }
        return NO;
    }
    return YES;
}

@implementation NSObject (StringHelper)

- (nullable NSString *)stringify {
    if ([self isKindOfClass:[NSString class]]) {
        return (NSString *)self;
    } else if ([self isKindOfClass:[NSNumber class]]) {
        return ((NSNumber *)self).stringValue;
    } else {
        return [self description];
    }
}

@end

@implementation NSString (StringHelper)


- (NSUInteger)occurrencesCountOfString:(NSString *)substring {
    substring = [substring stringify];
    if (substring.length == 0) {
        return 0;
    }
    
    NSInteger count = 0;
    NSRange searchRange = NSMakeRange(0, self.length);
    NSRange range;
    while ((range = [self rangeOfString:substring options:0 range:searchRange]).location != NSNotFound) {
        ++ count;
        searchRange.location = range.location + range.length;
        searchRange.length = self.length - searchRange.location;
    }
    return count;
}

- (NSString *)stringByConvertingCamelCaseToUnderscore {
    NSScanner *scanner = [NSScanner scannerWithString:self];
    scanner.caseSensitive = YES;
    
    NSCharacterSet *uppercase = [NSCharacterSet uppercaseLetterCharacterSet];
    NSCharacterSet *lowercase = [NSCharacterSet lowercaseLetterCharacterSet];
    
    NSString *buffer = nil;
    NSMutableString *output = [NSMutableString string];
    
    while (scanner.isAtEnd == NO) {
        
        if ([scanner scanCharactersFromSet:uppercase intoString:&buffer]) {
            [output appendString:[buffer lowercaseString]];
        }
        
        if ([scanner scanCharactersFromSet:lowercase intoString:&buffer]) {
            [output appendString:buffer];
            if (!scanner.isAtEnd)
                [output appendString:@"_"];
        }
    }
    
    return [output copy];
}

- (nullable NSString *)substringToIndexSafety:(NSUInteger)to {
    return to < self.length ? [self substringToIndex:to] : nil;
}

- (nullable NSString *)substringFromIndexSafety:(NSUInteger)from {
    return from < self.length ? [self substringFromIndex:from] : nil;
}

- (nullable NSString *)substringWithRangeSafety:(NSRange)range {
    if (range.location < self.length) {
        if (range.location + range.length < self.length) {
            return [self substringWithRange:range];
        } else {
            return [self substringFromIndex:range.location];
        }
    } else {
        return nil;
    }
}

@end




NS_ASSUME_NONNULL_END