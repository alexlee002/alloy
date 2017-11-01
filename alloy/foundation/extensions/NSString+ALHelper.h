//
//  NSString+Helper.h
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
/**
 * @return return NSNull if obj is nil, otherwise return obj itself;
 */
OBJC_EXPORT id           al_wrapNil  (id _Nullable obj);
/**
 * @return return nil if obj is NSNull, otherwise return obj itself;
 */
OBJC_EXPORT id _Nullable al_unwrapNil(id _Nullable obj);

/**
 * return string value of `obj`.  Check if obj can responds to SEL 'stringValue' and send message to SEL.
 * if object has no such SEL, return nil;
 * @see "-[NSObject(StringHelper) stringify]"
 */
OBJC_EXPORT NSString *_Nullable al_stringValue(id _Nullable obj);

/**
 * return if str1 is equals to str2
 * If str1 is nil or str2 is nil or not a NSString, return NO; others return [str1 isEqualToString:str2]
 */
OBJC_EXPORT BOOL             al_stringEquals       (NSString *_Nullable str1, NSString *_Nullable str2);

/**
 *  @return return empty string if parameter "string" is nil, otherwise return "string" itself.
 */
OBJC_EXPORT NSString         *al_stringOrEmpty     (NSString *_Nullable string);

/**
 *  @return return YES if parameter "string" is nil or empty string. otherwise return NO.
 */
OBJC_EXPORT BOOL             al_isEmptyString      (NSString *_Nullable string);
OBJC_EXPORT NSStringEncoding al_NSStringEncodingWithName(NSString *_Nullable encodingName);

#pragma mark -
@interface NSObject (ALStringHelper)

/**
 *  send message to SEL `stringValue` if object responds to the selector, 
 *  otherwise send message to SEL `description`
 */
- (NSString *)al_stringify;

@end


@interface NSString (ALStringHelper)

/**
 * @return return count of substring that occurrence in the specified string
 */
- (NSUInteger)al_occurrencesCountOfString:(NSString *)substring;

/**
 * eg: abcDefGh => abc_def_gh
 */
- (NSString *)al_stringByConvertingCamelCaseToUnderscore;

- (NSString *)al_stringByLowercaseFirst;
- (NSString *)al_stringbyUppercaseFirst;

/**
 *  @return if range.location >= string.length, return nil
 *          if range.location + range.length > string.length, return substring from range.location to the end of string.
 */
- (nullable NSString *)al_substringWithRange:(NSRange)range;
/**
 *  Returns the portion of string from the specified position;
 *  example:
 *      NSString *string = @"01234567";
 *      XCTAssertEqualObjects(@"567", [string al_substringFromIndex:5]);    // √
 *      XCTAssertEqualObjects(@"567", [string al_substringFromIndex:-3]);   // √
 *      XCTAssertNil([string al_substringFromIndex:10]);                    // √
 *      XCTAssertEqualObjects(string, [string al_substringFromIndex:-10]);  // √
 *
 *  @param   from   Refers to the position of the string to start cutting.
 *                  if from >= 0, the returned string will start at the start'th position in string.
 *                  if from >= string.length, nil will be returned;
 *                  if from < 0,  the returned string will start at the start'th character from the end of string.
 *  @return portion of string, or empty string, or nil;
 */
- (nullable NSString *)al_substringFromIndex:(NSInteger)from;

/**
 *  Returns the portion of string from begining to the specified position.
 *  example:
 *      NSString *string = @"01234567";
 *      XCTAssertEqualObjects(@"012", [string al_substringToIndex:3]);              // √
 *      XCTAssertEqualObjects(@"012", [string al_substringToIndex:-5]);             // √
 *      XCTAssertEqualObjects(string, [string al_substringToIndex:string.length]);  // √
 *      XCTAssertNil([string al_substringToIndex:-10]);                             // √
 *      XCTAssertEqualObjects(string, [string al_substringToIndex:10]);             // √
 *
 *  @param   to   Refers to the position of the string to start cutting.
 *                  if from >= 0, the returned string will start at the start'th position in string.
 *                  if from >= string.length, nil will be returned;
 *                  if from < 0,  the returned string will start at the start'th character from the end of string.
 *  @return portion of string, or empty string, or nil;
 */
- (nullable NSString *)al_substringToIndex:(NSInteger)to;

/**
 * Returns the portion of string from the specified position and specified length;
 *  example:
 *      NSString *string = @"01234567";
 *      XCTAssertEqualObjects(@"345", [string al_substringFromIndex:-5 length:3]);      // √
 *      XCTAssertEqualObjects(@"345", [string al_substringFromIndex:-5 length:-2]);     // √
 *      XCTAssertEqualObjects(@"345", [string al_substringFromIndex:3 length:-2]);      // √
 *      XCTAssertNil([string al_substringFromIndex:10 length:3]);                       // √
 *      XCTAssertNil([string al_substringFromIndex:-10 length:-10]);                    // √
 *      XCTAssertEqualObjects(@"34567", [string al_substringFromIndex:-5 length:10]);   // √
 *      XCTAssertEqualObjects(string, [string al_substringFromIndex:-10 length:10]);    // √
 *
 *  @param   from   Refers to the position of the string to start cutting.
 *                  if from >= 0, the returned string will start at the start'th position in string.
 *                  if from < 0,  the returned string will start at the start'th character from the end of string.
 *
 *  @param   length  Length of the string to cut from the string.
 *                  if length > 0, the string returned will contain at most length characters beginning from start
 *                                  (depending on the length of string).
 *                  if length < 0, then that many characters will be omitted from the end of string
 *                                  (after the {from} position has been calculated when a {from} is negative).
 *                                  If {from} denotes the position of this truncation or beyond, nil will be returned.
 *                  if length == 0, an empty string will be returned.
 *
 *  @return portion of string, or empty string, or nil;
 */
- (nullable NSString *)al_substringFromIndex:(NSInteger)from length:(NSInteger)length;

/**
 *  Returns the portion of string from the specified position;
 *
 *  @param  from    the position of the string to start cutting. if {from} is out of bounds, return nil;
 *
 *  @return nil if from is out of bounds, othwise return the substring.
 */
- (nullable NSString *)al_substringFromIndexSafely:(NSUInteger)from;

/**
 *  Returns the portion of string start from begining to the specified position;
 *
 *  @param  to    the position of the string to stop cutting. if {to} is out of bounds, return the whole string;
 *
 *  @return the substring or the whole string.
 */
- (nullable NSString *)al_substringToIndexSafely:(NSUInteger)to;

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
OBJC_EXPORT NSString *_Nullable al_bytesToHexStr(const char *bytes, size_t len);

//convert number from base-10 to base-N, N <= 62;
OBJC_EXPORT NSString *_Nullable decimalToBaseN(uint64_t num, uint8_t base);
OBJC_EXPORT uint64_t baseNToDecimal(const char *s, uint8_t base);

NS_ASSUME_NONNULL_END
