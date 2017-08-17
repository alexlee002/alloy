//
//  URLHelper.m
//  patchwork
//
//  Created by Alex Lee on 5/27/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALURLHelper.h"
#import "BlocksKit.h"
#import "NSArray+ArrayExtensions.h"
#import "ALUtilitiesHeader.h"
#import "NSString+ALHelper.h"
#import "ALOrderedMap.h"


AL_FORCE_INLINE NSString *URLParamStringify(id _Nullable value) {
    NSString *canonicalString = nil;
    if ([value isKindOfClass:[NSString class]]) {
        canonicalString = (NSString *)value;
    } else if ([NSJSONSerialization isValidJSONObject:value]) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:value options:0 error:nil];
        canonicalString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    } else {
        canonicalString = [value al_stringify];
    }
    
    return al_stringOrEmpty(canonicalString);
}


static AL_FORCE_INLINE NSArray<ALNSURLQueryItem *> *queryItemsFromQueryStirng(NSString *urlencodedQuery) {
    return [[[urlencodedQuery componentsSeparatedByString:@"&"] bk_select:^BOOL(NSString *itemString) {
        return ALCastToTypeOrNil(itemString, NSString).length > 0;
    }] bk_map:^ALNSURLQueryItem *(NSString *itemString) {
        NSArray *pairs = [ALCastToTypeOrNil(itemString, NSString) componentsSeparatedByString:@"="];
        return [ALNSURLQueryItem queryItemWithName:[pairs.firstObject ?: @"" al_stringByURLDecoding]
                                             value:[[pairs al_objectAtIndexSafely:1] al_stringByURLDecoding]];
    }];
}

static AL_FORCE_INLINE void addOrReplaceQueryItems(NSMutableArray<ALNSURLQueryItem *> *originalItems,
                                         NSArray<ALNSURLQueryItem *> *addingItems) {
    ALOrderedMap<NSString *, NSString *> *orderedMap = [ALOrderedMap orderedMap];
    [[originalItems arrayByAddingObjectsFromArray:addingItems] bk_each:^(ALNSURLQueryItem *item) {
        [orderedMap setObject:item.value forKey:item.name];
    }];

    [originalItems removeAllObjects];
    [orderedMap
        enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSString *_Nonnull obj, BOOL *_Nonnull stop) {
            [originalItems addObject:[ALNSURLQueryItem al_queryItemWithName:key rawValue:obj]];
        }];
}

static AL_FORCE_INLINE NSString *queryStringFromQueryItems(NSArray<ALNSURLQueryItem *> *items) {
    return [[items bk_map:^NSString *(ALNSURLQueryItem *item) {
        NSString *string = [item.name al_stringByURLEncodingAs:ALURLComponentQuery];
        if (item.value != nil) {
            string = [string stringByAppendingFormat:@"=%@", [item.value al_stringByURLEncodingAs:ALURLComponentQuery]];
        }
        return string;
    }] componentsJoinedByString:@"&"];
}

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0 || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_10
@implementation ALNSURLQueryItem

@synthesize name  = _name;
@synthesize value = _value;

+ (instancetype)queryItemWithName:(NSString *)name value:(NSString *)value {
    al_guard_or_return(([name isKindOfClass:[NSString class]] &&
                        (value == nil || [value isKindOfClass:[NSString class]])),
                       nil);

    ALNSURLQueryItem *item = [[ALNSURLQueryItem alloc] init];
    item->_name            = [name copy];
    item->_value           = [value copy];
    return item;
}

+ (instancetype)al_queryItemWithName:(NSString *)name rawValue:(nullable id)rawValue {
    return [self queryItemWithName:URLParamStringify(name) value:URLParamStringify(rawValue)];
}

- (NSString *)description {
    return [[super description] stringByAppendingFormat:@" name:%@; value: %@", self.name, self.value];
}

@end

#else

@implementation NSURLQueryItem(ALURLHelper)

+ (instancetype)al_queryItemWithName:(NSString *)name rawValue:(nullable id)rawValue {
    return [self queryItemWithName:URLParamStringify(name) value:URLParamStringify(rawValue)];
}

@end

#endif


@implementation NSURL (ALURLHelper)

- (NSURL * (^)(NSString *name, id value))SET_QUERY_ITEM {
    return ^NSURL *(NSString *name, id value) {
        return [self URLByAppendingQueryItems:@[ al_URLQueryItem(name, value) ] replace:YES];
    };
}

- (NSURL *)URLBySettingQueryParamsOfDictionary:(NSDictionary<NSString *, id> *)itemDict {
    return [self URLByAppendingQueryItems:[itemDict.allKeys bk_map:^ALNSURLQueryItem *(NSString *name) {
                     return al_URLQueryItem(name, itemDict[name]);
                 }]
                                  replace:YES];
}

- (NSURL *)URLByAppendingQueryItems:(NSArray<ALNSURLQueryItem *> *)items replace:(BOOL)replace {
    NSURLComponents *comps = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:(self.absoluteURL != nil)];
    NSArray<ALNSURLQueryItem *> *queryItems = nil;
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0 || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_10
    queryItems = queryItemsFromQueryStirng(comps.percentEncodedQuery);
#else
    queryItems = comps.queryItems;
#endif
    if (replace) {
        NSMutableArray<ALNSURLQueryItem *> *resultItems =
            queryItems == nil ? [NSMutableArray array] : [queryItems mutableCopy];
        addOrReplaceQueryItems(resultItems, items);
        queryItems = resultItems;
    } else {
        queryItems = (queryItems == nil) ? items : [queryItems arrayByAddingObjectsFromArray:items];
    }

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0 || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_10
    comps.percentEncodedQuery = queryStringFromQueryItems(queryItems);
#else
    comps.queryItems = queryItems;
#endif
    return comps.URL;
}

+ (NSString *)queryStringWithQueryItems:(NSArray<ALNSURLQueryItem *> *)queryItems {
    return queryStringFromQueryItems(queryItems);
}

+ (NSString *)queryStringWithQueryParamsOfDictionary:(NSDictionary<NSString *, id> *)itemsDict {
     return queryStringFromQueryItems([itemsDict.allKeys bk_map:^ALNSURLQueryItem *(NSString *name) {
         return [ALNSURLQueryItem al_queryItemWithName:name rawValue:itemsDict[name]];
     }]);
}

@end

@implementation NSString (ALURLHelper)

- (NSArray<ALNSURLQueryItem *> *)URLQueryItems {
    NSString *queryString = self;
    NSRange queryRange = [self URLQueryStringRange];
    if (queryRange.location != NSNotFound) {
        queryString = [self substringWithRange:queryRange];
    }
    return queryItemsFromQueryStirng(queryString);
}

- (NSDictionary<NSString *, NSString *> *)URLQueryItemsDictionary {
    NSArray *items = [self URLQueryItems];
    if (items == nil) {
        return nil;
    }
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [items bk_each:^(ALNSURLQueryItem *item) {
        dict[item.name] = item.value;
    }];
    return [dict copy];
}

- (NSRange)URLQueryStringRange {
    // @see RFC 1808: https://www.ietf.org/rfc/rfc1808.txt
    // URL Components: <scheme>://<net_loc>/<path>;<params>?<query>#<fragment>
    NSRange queryStringRange = NSMakeRange(NSNotFound, 0);

    NSUInteger startAt = [self rangeOfString:@"?"].location;
    if (startAt == NSNotFound) {
        startAt = [self rangeOfString:@"&"].location;
    }
    if (startAt != NSNotFound) {
        startAt = startAt + 1;
        NSInteger endAt =
            [self rangeOfString:@"#" options:0 range:NSMakeRange(startAt, self.length - startAt)].location;
        endAt = endAt == NSNotFound ? self.length : endAt;

        queryStringRange.location = startAt;
        queryStringRange.length   = endAt - startAt;
    }
    return queryStringRange;
}

- (NSString * (^)(NSString *name, id value))SET_QUERY_ITEM {
    return ^NSString *(NSString *name, id value) {
        return [self URLStringByAppendingQueryItems:@[al_URLQueryItem(name, value)] replace:YES];
    };
}

- (NSString *)URLStringBySettingQueryParamsOfDictionary:(NSDictionary<NSString *, id> *)itemDict {
    return [self URLStringByAppendingQueryItems:[itemDict.allKeys bk_map:^ALNSURLQueryItem *(NSString *name) {
                     return al_URLQueryItem(name, itemDict[name]);
                 }]
                                        replace:YES];
}

- (NSString *)URLStringByAppendingQueryItems:(NSArray<ALNSURLQueryItem *> *)items replace:(BOOL)replace {
    NSURL *URL = [NSURL URLWithString:self];
    if (URL != nil) {
        return [URL URLByAppendingQueryItems:items replace:replace].absoluteString;
    }

    NSRange queryStringRange = [self URLQueryStringRange];
    NSString *query = [self al_substringWithRangeSafety:queryStringRange];

    NSArray<ALNSURLQueryItem *> *queryItems = nil;
    if (!al_isEmptyString(query)) {
        queryItems = queryItemsFromQueryStirng(query);
    }

    if (replace) {
        NSMutableArray<ALNSURLQueryItem *> *resultItems =
            queryItems == nil ? [NSMutableArray array] : [queryItems mutableCopy];
        addOrReplaceQueryItems(resultItems, items);
        queryItems = resultItems;
    } else {
        queryItems = (queryItems == nil) ? items : [queryItems arrayByAddingObjectsFromArray:items];
    }
    
    // queryString with URLEncoded
    query = queryStringFromQueryItems(queryItems);
    
    if (al_isEmptyString(query)) {
        return self;
    }

    if (queryStringRange.location == NSNotFound) {
        return [self stringByAppendingFormat:@"?%@", query];
    }

    NSMutableString *resultUrl = [NSMutableString stringWithString:[self substringToIndex:queryStringRange.location]];
    [resultUrl appendString:@"?"];
    [resultUrl appendString:query];
    NSUInteger queryEndIndex = queryStringRange.location + queryStringRange.length;
    if (self.length > queryEndIndex) {
        [resultUrl appendFormat:@"%@", [self substringFromIndex:queryEndIndex]];
    }
    return [resultUrl copy];
}

- (NSString *)al_stringByURLEncodingAs:(ALURLComponent)component {
    if (component == ALURLComponentQuery) {
        return [self stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    }
    if (component == ALURLComponentPath || component == ALURLComponentParam) {
        return [self stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
    }
    if (component == ALURLComponentFragment) {
        return [self stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
    }
    if (component == ALURLComponentHost) {
        return [self stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
    }
    if (component == ALURLComponentUser) {
        return [self stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLUserAllowedCharacterSet]];
    }
    if (component == ALURLComponentPassword) {
        return [self stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPasswordAllowedCharacterSet]];
    }
    return self;
}

- (NSString *)al_stringByURLDecoding {
    return [self stringByRemovingPercentEncoding];
}


//- (NSString *)stringByURLEncoding {
//    NSString *resultStr = self;
//    
//    CFStringRef originalString = (__bridge CFStringRef) self;
//    CFStringRef leaveUnescaped = CFSTR(" ");
//    CFStringRef forceEscaped   = CFSTR("!*'();:@&=+$,/?%#[]");
//    
//    CFStringRef escapedStr;
//    escapedStr = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, originalString, leaveUnescaped,
//                                                         forceEscaped, kCFStringEncodingUTF8);
//    
//    if (escapedStr) {
//        NSMutableString *mutableStr = [NSMutableString stringWithString:(__bridge NSString *) escapedStr];
//        CFRelease(escapedStr);
//        
//        // replace spaces with plusses
//        [mutableStr replaceOccurrencesOfString:@" "
//                                    withString:@"%20"
//                                       options:0
//                                         range:NSMakeRange(0, [mutableStr length])];
//        resultStr = mutableStr;
//    }
//    return resultStr;
//}
//
//- (NSString *)stringByURLDecoding {
//    NSString *result = [self stringByReplacingOccurrencesOfString:@"+" withString:@" "];
//    result           = [result stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//    return result;
//}

@end
