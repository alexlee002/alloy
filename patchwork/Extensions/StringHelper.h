//
//  StringHelper.h
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

extern NSString *stringOrEmpty(NSString *_Nullable string);
extern BOOL      isEmptyString(NSString *_Nullable string);

@interface NSObject (StringHelper)

- (nullable NSString *)stringify;

@end


@interface NSString (StringHelper)

- (NSUInteger)occurrencesCountOfString:(NSString *)substring;
- (NSString *)stringByConvertingCamelCaseToUnderscore;
- (nullable NSString *)substringToIndexSafety:(NSUInteger)to;
- (nullable NSString *)substringFromIndexSafety:(NSUInteger)from;
- (nullable NSString *)substringWithRangeSafety:(NSRange)range;

@end


@interface NSString (NSURL_Utils)

@property(nonatomic, readonly) NSString * (^SET_QUERY_PARAM)(NSString *key, id value);

- (NSString *)stringbyAppendingQueryItems:(NSDictionary<NSString *, id> *)items;
- (NSString *)stringByURLEncoding;
- (NSString *)stringByURLDecoding;
@end

NS_ASSUME_NONNULL_END