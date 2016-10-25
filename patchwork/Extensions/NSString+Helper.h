//
//  NSString+Helper.h
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UtilitiesHeader.h"

NS_ASSUME_NONNULL_BEGIN

extern id           wrapNil  (id _Nullable obj);
extern id _Nullable unwrapNil(id _Nullable obj);

/**
 * return string value of `obj`.  Check if obj can responds to SEL 'stringValue' and send message to SEL.
 * if object has no such SEL, return nil;
 * @see "-[NSObject(StringHelper) stringify]"
 */
extern NSString *_Nullable stringValue(id _Nullable obj);

extern NSString         *stringOrEmpty     (NSString *_Nullable string);
extern BOOL             isEmptyString      (NSString *_Nullable string);
extern NSStringEncoding NSStringEncodingWithName(NSString *_Nullable encodingName);

@interface NSObject (StringHelper)

/**
 *  send message to SEL `stringValue` if object responds to the selector, 
 *  otherwise send message to SEL `description`
 */
- (NSString *)stringify;

@end


@interface NSString (StringHelper)

- (NSUInteger)occurrencesCountOfString:(NSString *)substring;
- (NSString *)stringByConvertingCamelCaseToUnderscore;

- (nullable NSString *)substringToIndexSafety:(NSUInteger)to;
- (nullable NSString *)substringFromIndexSafety:(NSUInteger)from;
- (nullable NSString *)substringWithRangeSafety:(NSRange)range;

+ (NSString *)UUIDString;

- (BOOL)containsEmojiCharacters;
- (NSComparisonResult)compareUsingPinyinTo:(NSString *)other;
- (NSComparisonResult)compareUsingGB2312To:(NSString *)other;

+ (NSString *)stringByFormattingSize:(int64_t)bytesCount;
+ (NSString *)stringByFormattingSize:(int64_t)bytesCount maxUnits:(NSByteCountFormatterUnits)maxUnits;
+ (NSString *)stringByFormattingSize:(int64_t)bytesCount
                            maxUnits:(NSByteCountFormatterUnits)maxUnits
                       decimalPlaces:(uint)places;
@end

@interface NSString (ALRegularExpressions)

- (nullable NSString *)stringByMatching:(NSString *)pattern captureRangeAt:(NSInteger)index;
- (BOOL)matchesPatterh:(NSString *)pattern;
@end


NS_ASSUME_NONNULL_END
