//
//  URLHelper.h
//  patchwork
//
//  Created by Alex Lee on 5/27/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALMacros.h"

// @see RFC 1808: https://www.ietf.org/rfc/rfc1808.txt
// URL Components: <scheme>://<net_loc>/<path>;<params>?<query>#<fragment>
// <net_loc
typedef NS_ENUM(NSInteger, ALURLComponent) {
    ALURLComponentScheme,
    ALURLComponentUser,
    ALURLComponentPassword,
    ALURLComponentHost,
    ALURLComponentPort,
    ALURLComponentPath,
    ALURLComponentParam,
    ALURLComponentQuery,        // the query string
    ALURLComponentQueryItem,    // the query item (name / value), not an independent url component, jus use in urlencode
    ALURLComponentFragment
};

NS_ASSUME_NONNULL_BEGIN

/*!
 * return string transformed from value.
 * try to get string via "al_stringValue(value)", if OK, return the string;
 * otherwise, try to convert value to JSON string, if OK, return the JSON string.
 * otherwise, return nil.
 */
OBJC_EXPORT NSString *_Nullable ALURLParamStringify(id _Nullable value);

@interface ALURLQueryItem : NSURLQueryItem
@property(readonly)           NSString *percentEncodedName;
@property(readonly, nullable) NSString *percentEncodedValue;

/*!
 * initialize an ALURLQueryItem with NSURLQueryItem.
 *
 * @param src       source query item
 * @param encoded   indicates if the parameter "src" has been encoded.
 */
+ (instancetype)queryItemWithItem:(NSURLQueryItem *)src percentEncoded:(BOOL)encoded;

/*!
 *  @param name     item name
 *  @param rawValue item value, convert to NSString via "ALURLParamStringify".  @see ALURLParamStringify
 */
+ (instancetype)queryItemWithName:(NSString *)name rawValue:(nullable id)rawValue;

/*!
 *  @param name     percentEncoded item name
 *  @param value    percentEncoded item value,
 */
+ (instancetype)queryItemWithPercentEncodedName:(NSString *)name percentEncodedValue:(nullable NSString *)value;

@end

/*!
 * import features to lower version of iOS / OSX
 */
@interface NSURLComponents (ALCompatible)
/*!
 * @see compatible with "queryItems"
 */
@property (nullable, copy, setter=al_setQueryItems:) NSArray<ALURLQueryItem *> *al_queryItems;

@end


#define al_URLQueryItem(name, value) [ALURLQueryItem al_queryItemWithName:(name) rawValue:(value)]

@interface NSURL (ALURLHelper)

// add new query key-value params to URL, or if the parameter with the same name is existed in the original URL,
// the existed value will be replaced
@property(readonly) NSURL * (^AL_SET_QUERY_ITEM)(NSString *name, id _Nullable value);

/**
 *  Append query key-value params to an existing URL
 *
 *  @param queryItems       query items.
 *  @param replaceExisted   Whether to replace the value of the existing query item with the same name. If YES, all the
 * value of the items with the same name will be replaced. If NO, just appending the new query items, that is, there
 * would be more than one query item with the same name.
 *
 *  @return new instance of URL with URLEncoded query string
 */
- (NSURL *)al_URLByAppendingQueryItems:(NSArray<ALURLQueryItem *> *)queryItems deduplicate:(BOOL)replaceExisted;

- (NSURL *)al_URLByAppendingQueryItemsWithDictionary:(NSDictionary<NSString *, id> *)itemDict
                                      percentEncoded:(BOOL)encoded
                                         deduplicate:(BOOL)replaceExisted;

- (NSArray<ALURLQueryItem *> *)al_queryItems;

- (NSURLComponents *)al_URLComponentByResolvingAgainstBaseURL:(BOOL)resolve;

@end

@interface NSString (ALURLHelper)
// @see NSURL (ALURLHelper)
@property(readonly) NSString * (^AL_SET_QUERY_ITEM)(NSString *name, id _Nullable value);

/**
 *  Append query key-value params to an existing URLString. if the existing URLString is malformed URL, nil will be
 * return.
 *
 *  @param queryItems   query items to appending.
 *  @param replace      Whether to replace the value of the existing query item with the same name. if YES, all the
 * value of the items with the same name will be replaced. if NO, just appending the new query items, that is, there
 * would be more than one query item with the same name.
 *
 *  @return new instance of URL string with URLEncoded query string
 */
- (nullable NSString *)al_URLStringByAppendingQueryItems:(NSArray<ALURLQueryItem *> *)queryItems
                                             deduplicate:(BOOL)replace;

- (nullable NSString *)al_URLStringByAppendingQueryItemsWithDictionary:(NSDictionary<NSString *, id> *)itemDict
                                                        percentEncoded:(BOOL)encoded
                                                           deduplicate:(BOOL)replace;

/*!
 *  appending "queryItems" to the existing query string.
 *  Note that the whole string "self" will be treated as the query component.
 */
- (NSString *)al_URLQueryStringByAppendingQueryItems:(NSArray<ALURLQueryItem *> *)queryItems
                                         deduplicate:(BOOL)replace;

- (NSString *)al_URLQueryStringByAppendingQueryItemsWithDictionary:(NSDictionary<NSString *, id> *)itemDict
                                                    percentEncoded:(BOOL)encoded
                                                       deduplicate:(BOOL)replace;

/*!
 *  try to parse the url string "self" and get the range of query.
 *  @see RFC 1808: https://www.ietf.org/rfc/rfc1808.txt
 *  URL Components: <scheme>://<net_loc>/<path>;<params>?<query>#<fragment>
 */
- (NSRange)al_URLQueryStringRange;

/**
 *  Extract query items from 'self'.  The string 'self' must be percent-encoded.
 *  Try to extract query string from 'self', if fail, use 'self' as query string.
 *
 *  @return array of query items.
 */
- (nullable NSArray<ALURLQueryItem *> *)al_URLQueryItems;

/**
 *  @return dictionary of un-percent-encoded query items
 */
- (nullable NSDictionary<NSString *, NSString *> *)al_URLQueryItemsDictionary;

/*!
 *  Note: if you need to encode the query item name / value, the value of parameter "component" should be
 * "ALURLComponentQueryItem", otherwise, the character "&", "=" will not be escaped. The "ALURLComponentQuery" is used
 * to encode the whole query string.
 */
- (nullable NSString *)al_stringByURLEncodingAs:(ALURLComponent)component;
- (nullable NSString *)al_stringByURLDecoding;

// string to NSURL
- (nullable NSURL *)al_URL;
- (nullable NSURL *)al_URLRelativeToURL:(NSURL *)baseURL;

- (nullable NSURLComponents *)al_URLComponents;

/*!
 * @param   part        which url component part the string will be set.
 * @param   encoded     YES if the string is already perecnt-encoded.
 */
- (NSURLComponents *)al_URLComponentByResolvingAs:(ALURLComponent)part percentEncoded:(BOOL)encoded;

@end

@interface ALURLHelper : NSObject

/*!
 * @return the percent-encoded query string
 */
+ (NSString *)queryStringWithItems:(NSArray<ALURLQueryItem *> *)queryItems;

/*!
 *  constructs a percent encoded url query string by specified query items.
 *
 *  @param itemDict     name/value pairs of query items
 *  @param encoded      indicates whether the parameter "queryItems" has already been percent-encoded.
 *
 *  @return the percent-encoded query string
 */
+ (NSString *)queryStringWithDictionary:(NSDictionary<NSString *, id> *)itemDict percentEncoded:(BOOL)encoded;

@end

@interface NSCharacterSet (ALURLHelper)
/*!
 * character set for url query item name and value.
 */
@property (class, readonly, copy) NSCharacterSet *al_URLQueryItemAllowedCharacterSet;
@end


NS_ASSUME_NONNULL_END
