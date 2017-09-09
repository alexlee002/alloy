//
//  StringHelper.m
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "NSString+ALHelper.h"
#import "BlocksKit.h"
#import "NSCache+ALExtensions.h"
#import "AL_MD5.h"
#import <objc/message.h>
#import "ALLogger.h"
#import "ALUtilitiesHeader.h"

NS_ASSUME_NONNULL_BEGIN

AL_FORCE_INLINE id al_wrapNil(id _Nullable obj) {
    return obj == nil ? NSNull.null : obj;
}

AL_FORCE_INLINE id _Nullable al_unwrapNil(id _Nullable obj) {
    return obj == NSNull.null ? nil : obj;
}

AL_FORCE_INLINE NSString *_Nullable al_stringValue(id _Nullable obj) {
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

AL_FORCE_INLINE BOOL al_stringEquals(NSString *_Nullable str1, NSString *_Nullable str2) {
    if (ALCastToTypeOrNil(str1, NSString) == nil) {
        return NO;
    }
    if (ALCastToTypeOrNil(str2, NSString) == nil) {
        return NO;
    }
    return [str1 isEqualToString:str2];
}

AL_FORCE_INLINE NSString *al_stringOrEmpty(NSString *_Nullable string) {
    return al_stringValue(string) ?: @"";
}

AL_FORCE_INLINE BOOL al_isEmptyString(NSString *_Nullable string) {
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

AL_FORCE_INLINE NSStringEncoding al_NSStringEncodingWithName(NSString *_Nullable encodingName) {
    CFStringEncoding cfEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef) encodingName);
    if (cfEncoding != kCFStringEncodingInvalidId) {
        return CFStringConvertEncodingToNSStringEncoding(cfEncoding);
    }
    ALLogWarn(@"Can not convert charset name '%@' to encoding. using default encoding as NSUTF8StringEncoding",
              encodingName);
    return NSUTF8StringEncoding;
}

AL_FORCE_INLINE static NSComparisonResult compareStringsUsingLocale(NSString *str1, NSString *str2, NSString *localeName) {
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:localeName];
    NSComparisonResult result = [str1 compare:str2 options:0 range:NSMakeRange(0, [str1 length]) locale:locale];
    return result;
}

@implementation NSObject (ALStringHelper)

- (NSString *)al_stringify {
    return al_stringValue(self) ?: [self description];
}

@end

@implementation NSString (ALStringHelper)


- (NSUInteger)al_occurrencesCountOfString:(NSString *)substring {
    substring = [substring al_stringify];
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

- (NSString *)al_stringByConvertingCamelCaseToUnderscore {
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

- (NSString *)al_stringByLowercaseFirst {
    if (self.length == 0) {
        return self;
    }
    return [self stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                         withString:[[self substringToIndex:1] lowercaseString]];
}

- (NSString *)al_stringbyUppercaseFirst {
    if (self.length == 0) {
        return self;
    }
    return [self stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                         withString:[[self substringToIndex:1] uppercaseString]];
}

- (nullable NSString *)al_substringToIndexSafety:(NSInteger)to {
    NSParameterAssert(to <= self.length && to >= -self.length);
    to = to < 0 ? self.length + to : to;
    return [self substringToIndex:to];
}

- (nullable NSString *)al_substringFromIndexSafety:(NSInteger)from {
    NSParameterAssert(from < self.length && from >= -self.length);
    from = from < 0 ? self.length + from : from;
    return [self substringFromIndex:from];
}

- (nullable NSString *)al_substringWithRangeSafety:(NSRange)range {
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

- (nullable NSString *)al_substringFromIndex:(NSInteger)from length:(NSInteger)length {
    NSUInteger start = from > 0 ? from : self.length + from;
    NSUInteger end = length > 0 ? start + length : self.length + length;
    return [[self al_substringFromIndexSafety:start] al_substringToIndexSafety:end];
}

+ (NSString *)al_UUIDString {
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidString = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
    CFRelease(uuid);
    return uuidString;
}

- (BOOL)al_containsEmojiCharacters {
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

- (NSComparisonResult)al_compareUsingPinyinTo:(NSString *)other {
    return compareStringsUsingLocale(self, other, @"zh@collation=pinyin");
}

- (NSComparisonResult)al_compareUsingGB2312To:(NSString *)other {
    return compareStringsUsingLocale(self, other, @"zh@collation=gb2312");
}

+ (NSString *)al_stringByFormattingSize:(int64_t)bytesCount {
    return [self al_stringByFormattingSize:bytesCount maximumUnit:NSByteCountFormatterUseDefault decimalPlaces:2];
}

+ (NSString *)al_stringByFormattingSize:(int64_t)bytesCount maximumUnit:(NSByteCountFormatterUnits)maxUnit {
    return [self al_stringByFormattingSize:bytesCount maximumUnit:maxUnit decimalPlaces:2];
}

+ (NSString *)al_stringByFormattingSize:(int64_t)bytesCount
                            maximumUnit:(NSByteCountFormatterUnits)maxUnit
                          decimalPlaces:(uint)places {
    maxUnit = maxUnit == NSByteCountFormatterUseAll ? NSByteCountFormatterUseDefault : maxUnit;
    
    NSArray<NSString *> *unitNames = @[@"B", @"KB", @"MB", @"GB", @"TB", @"PB", @"EB", @"ZB", @"YB"];
    
    NSInteger maxUnitsIndex = unitNames.count - 1;
    if (maxUnit != NSByteCountFormatterUseDefault) {
        maxUnitsIndex = 0;
        while ((maxUnit = maxUnit >> 1) > 0 && maxUnitsIndex < unitNames.count) {
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

- (nullable NSRegularExpression *)al_regularExpressionWithPattern:(NSString *)pattern {
    NSString *cacheKey = [@"ALRegularExpressions_KEY$" stringByAppendingString:[pattern al_MD5Hash]];
    
    NSRegularExpression *regex = [[NSCache al_sharedCache] objectForKey:cacheKey];
    if (![regex isKindOfClass:[NSRegularExpression class]]) {
        ALAssert(regex == nil, @"cached object key conflict: %@", regex);
        NSError *error;
        regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
        if (regex != nil) {
            [[NSCache al_sharedCache] setObject:regex forKey:cacheKey];
        } else {
            ALLogWarn(@"ERROR: %@", error);
        }
    }
    return regex;
}

- (nullable NSString *)al_stringByMatching:(NSString *)pattern captureRangeAt:(NSInteger)index {
    NSRegularExpression *regex = [self al_regularExpressionWithPattern:pattern];
    NSTextCheckingResult *result = [regex firstMatchInString:self options:0 range:NSMakeRange(0, self.length)];
    if (result.numberOfRanges > 1) {
        return [self al_substringWithRangeSafety:[result rangeAtIndex:index]];
    }
    return nil;
}

- (BOOL)al_matchesPattern:(NSString *)pattern {
    NSRegularExpression *regex = [self al_regularExpressionWithPattern:pattern];
    NSTextCheckingResult *result = [regex firstMatchInString:self options:0 range:NSMakeRange(0, self.length)];
    return result.range.length == self.length;
}


@end

@implementation NSData(StringHelper)

- (NSString *)al_hexString {
    return al_bytesToHexStr(self.bytes, self.length);
}

- (NSString *)al_debugDescription {
    NSMutableString *dump = [NSMutableString string];
    NSInteger index = 0;
    while (index < MIN(16, self.length)) {
        [dump appendFormat:@"%@%@", [[self subdataWithRange:NSMakeRange(index, MIN(4, self.length - 4))] al_hexString],
                           (index + 4 < self.length ? @" " : @"")];
        index += 4;
    }
    if (self.length > index + 16) {
        [dump appendString:@"..."];
    }
    index = MAX(index, self.length - 16);
    while (index < self.length) {
        [dump appendFormat:@" %@", [[self subdataWithRange:NSMakeRange(index, MIN(4, self.length - 4))] al_hexString]];
        index += 4;
    }
    
    return [NSString stringWithFormat:@"<%@, %p; size=%ld, bytes:%@>", [self class], self, self.length, dump];
}

@end

AL_FORCE_INLINE NSString *al_bytesToHexStr(const char *bytes, size_t len) {
    if (bytes == NULL) {
        return nil;
    }
    if (len == 0) {
        return @"";
    }
    
    const char *hexChars = "0123456789abcdef";
    char *result = malloc(sizeof(char) * (len * 2 + 1));
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

AL_FORCE_INLINE NSString *decimalToBaseN(uint64_t num, uint8_t base) {
    al_c_guard_or_return(base <= 62, nil);
    const char *baseChar = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    int size = 64;
    char result[size];
    result[--size] = '\0';
    while (num > 0) {
        char c = baseChar[num % base];
        result[--size] = c;
        num /= base;
    }
    NSString *base36 = [NSString stringWithUTF8String:strdup(result + size)];
    return base36;
}

AL_FORCE_INLINE uint64_t baseNToDecimal(const char *s, uint8_t base) {
    al_c_guard_or_return(base <= 62, 0);
    uint64_t result = 0;
    int len = (int)strlen(s);
    for (int i = len - 1; i >= 0; --i) {
        char c = s[i];
        if (c >= '0' && c <= '9') {
            c -= '0';
        } else if (c >= 'a' && c <= 'z') {
            c -= 'a' - 10;
        } else if (c >= 'A' && c <= 'Z') {
            if (base > 36) {
                c -= 'A' - 36;
            } else {
                c -= 'A' - 10;
            }
        } else {
            NSCAssert(NO, @"invalid char '%c'!", c);
        }
        result += c * pow(base, len - i - 1);
    }
    return result;
}
NS_ASSUME_NONNULL_END
