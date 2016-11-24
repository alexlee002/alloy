//
//  StringHelper.m
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "NSString+Helper.h"
#import "BlocksKit.h"
#import "NSCache+ALExtensions.h"
#import "MD5.h"
#import <objc/message.h>
#import "ALLogger.h"

NS_ASSUME_NONNULL_BEGIN

FORCE_INLINE id wrapNil(id _Nullable obj) {
    return obj == nil ? NSNull.null : obj;
}

FORCE_INLINE id _Nullable unwrapNil(id _Nullable obj) {
    return obj == NSNull.null ? nil : obj;
}

FORCE_INLINE NSString *_Nullable stringValue(id _Nullable obj) {
    if ([obj isKindOfClass:NSString.class]) {
        return (NSString *)obj;
    } else if ([obj isKindOfClass:NSNumber.class]) {
        return ((NSNumber *)obj).stringValue;
    } else if ([obj isKindOfClass:NSURL.class]) {
        return ((NSURL *)obj).absoluteString;
    } else if ([obj respondsToSelector:@selector(stringValue)]) {
        return [obj stringValue];
    }
    return nil;
}

FORCE_INLINE BOOL stringEquals(NSString *_Nullable str1, NSString *_Nullable str2) {
    if (castToTypeOrNil(str1, NSString) == nil) {
        return NO;
    }
    if (castToTypeOrNil(str2, NSString) == nil) {
        return NO;
    }
    return [str1 isEqualToString:str2];
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

FORCE_INLINE NSStringEncoding NSStringEncodingWithName(NSString *_Nullable encodingName) {
    CFStringEncoding cfEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef) encodingName);
    if (cfEncoding != kCFStringEncodingInvalidId) {
        return CFStringConvertEncodingToNSStringEncoding(cfEncoding);
    }
    ALLogWarn(@"Can not convert charset name '%@' to encoding. using default encoding as NSUTF8StringEncoding",
              encodingName);
    return NSUTF8StringEncoding;
}

FORCE_INLINE static NSComparisonResult compareStringsUsingLocale(NSString *str1, NSString *str2, NSString *localeName) {
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:localeName];
    NSComparisonResult result = [str1 compare:str2 options:0 range:NSMakeRange(0, [str1 length]) locale:locale];
    return result;
}

@implementation NSObject (StringHelper)

- (NSString *)stringify {
    return stringValue(self) ?: [self description];
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
    scanner.charactersToBeSkipped = nil;
    
    NSCharacterSet *uppercase = [NSCharacterSet uppercaseLetterCharacterSet];
    NSCharacterSet *lowercase = [NSCharacterSet lowercaseLetterCharacterSet];
    NSCharacterSet *letters   = [NSCharacterSet letterCharacterSet];
    
    NSString *buffer = nil;
    NSMutableString *output = [NSMutableString string];
    
    while (scanner.isAtEnd == NO) {
        
        if ([scanner scanUpToCharactersFromSet:uppercase intoString:&buffer]) {
            [output appendString:[buffer lowercaseString]];
            if (!scanner.isAtEnd && [letters characterIsMember:[buffer characterAtIndex:buffer.length - 1]] ) {
                [output appendString:@"_"];
            }
        }
        if ([scanner scanUpToCharactersFromSet:lowercase intoString:&buffer]) {
            [output appendString:[buffer lowercaseString]];
        }
    }
    
    return [output copy];
}

- (NSString *)stringByLowercaseFirst {
    if (self.length == 0) {
        return self;
    }
    return [self stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                         withString:[[self substringToIndex:1] lowercaseString]];
}

- (NSString *)stringbyUppercaseFirst {
    if (self.length == 0) {
        return self;
    }
    return [self stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                         withString:[[self substringToIndex:1] uppercaseString]];
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

+ (NSString *)UUIDString {
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidString = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
    CFRelease(uuid);
    return uuidString;
}

- (BOOL)containsEmojiCharacters {
    __block BOOL returnValue = NO;
    [self
        enumerateSubstringsInRange:NSMakeRange(0, [self length])
                           options:NSStringEnumerationByComposedCharacterSequences
                        usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {

                            const unichar hs = [substring characterAtIndex:0];
                            // surrogate pair
                            if (0xd800 <= hs && hs <= 0xdbff) {
                                if (substring.length > 1) {
                                    const unichar ls = [substring characterAtIndex:1];
                                    const int uc     = ((hs - 0xd800) * 0x400) + (ls - 0xdc00) + 0x10000;
                                    if (0x1d000 <= uc && uc <= 0x1f77f) {
                                        returnValue = YES;
                                    }
                                }
                            } else if (substring.length > 1) {
                                const unichar ls = [substring characterAtIndex:1];
                                if (ls == 0x20e3) {
                                    returnValue = YES;
                                }

                            } else {
                                // non surrogate
                                if (0x2100 <= hs && hs <= 0x27ff) {
                                    returnValue = YES;
                                } else if (0x2B05 <= hs && hs <= 0x2b07) {
                                    returnValue = YES;
                                } else if (0x2934 <= hs && hs <= 0x2935) {
                                    returnValue = YES;
                                } else if (0x3297 <= hs && hs <= 0x3299) {
                                    returnValue = YES;
                                } else if (hs == 0xa9 || hs == 0xae || hs == 0x303d || hs == 0x3030 || hs == 0x2b55 ||
                                           hs == 0x2b1c || hs == 0x2b1b || hs == 0x2b50) {
                                    returnValue = YES;
                                }
                            }
                        }];

    return returnValue;
}

- (NSComparisonResult)compareUsingPinyinTo:(NSString *)other {
    return compareStringsUsingLocale(self, other, @"zh@collation=pinyin");
}

- (NSComparisonResult)compareUsingGB2312To:(NSString *)other {
    return compareStringsUsingLocale(self, other, @"zh@collation=gb2312");
}

+ (NSString *)stringByFormattingSize:(int64_t)bytesCount {
    return [self stringByFormattingSize:bytesCount maxUnits:NSByteCountFormatterUseDefault decimalPlaces:2];
}

+ (NSString *)stringByFormattingSize:(int64_t)bytesCount maxUnits:(NSByteCountFormatterUnits)maxUnits {
    return [self stringByFormattingSize:bytesCount maxUnits:maxUnits decimalPlaces:2];
}

+ (NSString *)stringByFormattingSize:(int64_t)bytesCount
                            maxUnits:(NSByteCountFormatterUnits)maxUnits
                       decimalPlaces:(uint)places {
    maxUnits = maxUnits == NSByteCountFormatterUseAll ? NSByteCountFormatterUseDefault : maxUnits;
    
    NSArray<NSString *> *unitNames = @[@"B", @"KB", @"MB", @"GB", @"TB", @"PB", @"EB", @"ZB", @"YB"];
    
    NSInteger maxUnitsIndex = unitNames.count - 1;
    if (maxUnits != NSByteCountFormatterUseDefault) {
        maxUnitsIndex = 0;
        while ((maxUnits = maxUnits >> 1) > 0 && maxUnitsIndex < unitNames.count) {
            maxUnitsIndex ++;
        }
    }

    NSInteger unitsIndex = 0;
    long double value = bytesCount * 1.f;
    while (value > 1000 && unitsIndex < maxUnitsIndex) {
        value /= 1024;
        unitsIndex ++;
    }
    NSString *formatPattern = [NSString stringWithFormat:@"%%.%df %@", places, unitNames[unitsIndex]];
    return [NSString stringWithFormat:formatPattern, (double)value];
}

@end

#pragma mark -
@implementation NSString (ALRegularExpressions)

- (nullable NSRegularExpression *)regularExpressionWithPattern:(NSString *)pattern {
    NSString *cacheKey = [@"ALRegularExpressions_KEY$" stringByAppendingString:[pattern MD5]];
    
    NSRegularExpression *regex = [[NSCache sharedCache] objectForKey:cacheKey];
    if (![regex isKindOfClass:[NSRegularExpression class]]) {
        NSAssert(regex == nil, @"cached object key conflict: %@", regex);
        NSError *error;
        regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
        if (regex != nil) {
            [[NSCache sharedCache] setObject:regex forKey:cacheKey];
        } else {
            ALLogWarn(@"ERROR: %@", error);
        }
    }
    return regex;
}

- (nullable NSString *)stringByMatching:(NSString *)pattern captureRangeAt:(NSInteger)index {
    NSRegularExpression *regex = [self regularExpressionWithPattern:pattern];
    NSTextCheckingResult *result = [regex firstMatchInString:self options:0 range:NSMakeRange(0, self.length)];
    if (result.numberOfRanges > 1) {
        return [self substringWithRangeSafety:[result rangeAtIndex:index]];
    }
    return nil;
}

- (BOOL)matchesPattern:(NSString *)pattern {
    NSRegularExpression *regex = [self regularExpressionWithPattern:pattern];
    NSTextCheckingResult *result = [regex firstMatchInString:self options:0 range:NSMakeRange(0, self.length)];
    return result.range.length == self.length;
}


@end

@implementation NSData(StringHelper)

- (NSString *)hexString {
    return bytesToHexStr(self.bytes, self.length);
}

@end

FORCE_INLINE NSString *bytesToHexStr(const char *bytes, size_t len) {
    if (len == 0 || bytes == NULL) {
#if DEBUG
        assert(bytes != NULL);
#endif
        return @"";
    }
    
    const char *hexChars = "0123456789abcdef";
    char *result = malloc(sizeof(char) * (len* 2 + 1));
    char *s = result;
    for (NSInteger i = 0; i < len; ++i) {
        (*s++) = hexChars[((*bytes & 0xF0) >> 4)];
        (*s++) = hexChars[ (*bytes & 0x0F)];
        bytes ++;
    }
    *s = '\0';
    NSString *resultString = [NSString stringWithUTF8String:result];
    free(result);
    return resultString;
}

NS_ASSUME_NONNULL_END
