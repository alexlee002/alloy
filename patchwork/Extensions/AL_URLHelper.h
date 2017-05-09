//
//  URLHelper.h
//  patchwork
//
//  Created by Alex Lee on 5/27/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALUtilitiesHeader.h"

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
    ALURLComponentQuery,
    ALURLComponentFragment
};

NS_ASSUME_NONNULL_BEGIN

extern NSString *URLParamStringify (id _Nullable value) AL_DEPRECATED("implements it in your app");

// As the same as NSURLQueryItem, but this class only available after iOS 8 / OSX 10.10
// using 'ALNSURLQueryItem' to Compatible with the eailier OS
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0 || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_10
@interface ALNSURLQueryItem : NSObject
@property(readonly)           NSString *name;
@property(readonly, nullable) NSString *value;

+ (nullable instancetype)queryItemWithName:(NSString *)name value:(nullable NSString *)value;

/**
 *  initialize query item with given 'name' and 'value'
 *
 *  @param name     item name
 *  @param rawValue if rawValue is not NSString, try to convert it to JSON string, if failed, using [rawValue
 * description];  see 'URLParamStringify(id)' and '-stringify'
 *
 *  @return ALNSURLQueryItem
 */
+ (instancetype)al_queryItemWithName:(NSString *)name rawValue:(nullable id)rawValue;

@end
#else 

@interface NSURLComponents(ALURLHelper)
//@see ALNSURLQueryItem
+ (instancetype)al_queryItemWithName:(NSString *)name rawValue:(nullable id)rawValue;
@end

@compatibility_alias ALNSURLQueryItem NSURLQueryItem;

#endif

#define al_URLQueryItem(name, value) [ALNSURLQueryItem al_queryItemWithName:(name) rawValue:(value)]

@interface NSURL (ALURLHelper)

// add new query key-value params to URL, or if the param with the same name is existed in the original URL, the value
// of the item will be replaced
@property(readonly) NSURL * (^SET_QUERY_ITEM)(NSString *name, id value);

/**
 *  Append query key-value params to an existing URL
 *
 *  @param queryItems key-values pairs WITHOUT url encoding
 *  @param replace    Whether to replace the value of the existing query item with the same name. if YES, all the value
 * of the items with the same name will be replaced. if NO, just appending the new query items, that is, there would be
 * more than one query item with the same name.
 *
 *  @return new instance of URL with URLEncoded query string
 */
- (NSURL *)URLByAppendingQueryItems:(NSArray<ALNSURLQueryItem *> *)queryItems replace:(BOOL)replace;
- (NSURL *)URLBySettingQueryParamsOfDictionary:(NSDictionary<NSString *, id> *)itemDict;

+ (NSString *)queryStringWithQueryItems:(NSArray<ALNSURLQueryItem *> *)queryItems;
+ (NSString *)queryStringWithQueryParamsOfDictionary:(NSDictionary<NSString *, id> *)itemDict;

@end

@interface NSString (ALURLHelper)
// @see NSURL (ALURLHelper)
@property(readonly) NSString * (^SET_QUERY_ITEM)(NSString *name, id value);

/**
 *  Append query key-value params to an existing URLString
 *
 *  @param queryItems key-values pairs WITHOUT url encoding
 *  @param replace    Whether to replace the value of the existing query item with the same name. if YES, all the value
 * of the items with the same name will be replaced. if NO, just appending the new query items, that is, there would be
 * more than one query item with the same name.
 *
 *  @return new instance of URL string with URLEncoded query string
 */
- (NSString *)URLStringByAppendingQueryItems:(NSArray<ALNSURLQueryItem *> *)queryItems replace:(BOOL)replace;
- (NSString *)URLStringBySettingQueryParamsOfDictionary:(NSDictionary<NSString *, id> *)itemDict;

- (NSRange)URLQueryStringRange;
/**
 *  extract query items from 'self'.
 *  Try to extract query string from 'self', if fail, use 'self' as query string;  and then extract query items from query string.
 *
 *  @return array of query items
 */
- (nullable NSArray<ALNSURLQueryItem *> *)URLQueryItems;
- (nullable NSDictionary<NSString *, NSString *> *)URLQueryItemsDictionary;

- (NSString *)al_stringByURLEncodingAs:(ALURLComponent)component;
- (NSString *)al_stringByURLDecoding;
@end


NS_ASSUME_NONNULL_END
