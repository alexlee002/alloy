//
//  NSString+Helper.h
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALUtilitiesHeader.h"

NS_ASSUME_NONNULL_BEGIN

extern id           al_wrapNil  (id _Nullable obj);
extern id _Nullable al_unwrapNil(id _Nullable obj);

/**
 * return string value of `obj`.  Check if obj can responds to SEL 'stringValue' and send message to SEL.
 * if object has no such SEL, return nil;
 * @see "-[NSObject(StringHelper) stringify]"
 */
extern NSString *_Nullable al_stringValue(id _Nullable obj);

/**
 * return if str1 is equals to str2
 * If str1 is nil or str2 is nil or not a NSString, return NO; others return [str1 isEqualToString:str2]
 */
extern BOOL             al_stringEquals       (NSString *_Nullable str1, NSString *_Nullable str2);
extern NSString         *al_stringOrEmpty     (NSString *_Nullable string);
extern BOOL             al_isEmptyString      (NSString *_Nullable string);
extern NSStringEncoding al_NSStringEncodingWithName(NSString *_Nullable encodingName);

@interface NSObject (ALStringHelper)

/**
 *  send message to SEL `stringValue` if object responds to the selector, 
 *  otherwise send message to SEL `description`
 */
- (NSString *)al_stringify;

@end


@interface NSString (ALStringHelper)

- (NSUInteger)al_occurrencesCountOfString:(NSString *)substring;
- (NSString *)al_stringByConvertingCamelCaseToUnderscore;

- (NSString *)al_stringByLowercaseFirst;
- (NSString *)al_stringbyUppercaseFirst;

- (nullable NSString *)al_substringToIndexSafety:(NSUInteger)to;
- (nullable NSString *)al_substringFromIndexSafety:(NSUInteger)from;
- (nullable NSString *)al_substringWithRangeSafety:(NSRange)range;

/**
 * return a sub-string from a string
 *
 * @param   from    Refers to the position of the string to start cutting.
                    A positive number : Start at the specified position in the string.
                    A negative number : Start at a specified position from the end of the string.
 *
 * @param   length  Length of the string to cut from the string.
                    A positive number : Start at the specified position in the string.
                    A negative number : Start at a specified position from the end of the string.
 *
 */
- (nullable NSString *)al_substringFromIndex:(NSInteger)from length:(NSInteger)length;

+ (NSString *)al_UUIDString;

- (BOOL)al_containsEmojiCharacters;
- (NSComparisonResult)al_compareUsingPinyinTo:(NSString *)other;
- (NSComparisonResult)al_compareUsingGB2312To:(NSString *)other;

+ (NSString *)al_stringByFormattingSize:(int64_t)bytesCount;
+ (NSString *)al_stringByFormattingSize:(int64_t)bytesCount maximumUnit:(NSByteCountFormatterUnits)maxUnit;
+ (NSString *)al_stringByFormattingSize:(int64_t)bytesCount
                            maximumUnit:(NSByteCountFormatterUnits)maxUnits
                          decimalPlaces:(uint)places;
@end

@interface NSString (ALRegularExpressions)

- (nullable NSString *)al_stringByMatching:(NSString *)pattern captureRangeAt:(NSInteger)index;
- (BOOL)al_matchesPattern:(NSString *)pattern;
@end

@interface NSData(ALStringHelper)
// convert bytes to hexadecimal string(lowercase)
- (NSString *)al_hexString;

- (NSString *)al_debugDescription;

@end

// convert bytes to hexadecimal string(lowercase)
extern NSString *_Nullable al_bytesToHexStr(const char *bytes, size_t len);

NS_ASSUME_NONNULL_END
