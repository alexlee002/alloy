//
//  URLHelper.m
//  patchwork
//
//  Created by Alex Lee on 5/27/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "URLHelper.h"
#import "BlocksKit.h"
#import "NSArray+ArrayExtensions.h"
#import "UtilitiesHeader.h"
#import "NSString+Helper.h"
#import "ALOrderedMap.h"


FORCE_INLINE NSString *URLParamStringify(id _Nullable value) {
    NSString *canonicalString = nil;
    if ([value isKindOfClass:[NSString class]]) {
        canonicalString = (NSString *)value;
    } else if ([NSJSONSerialization isValidJSONObject:value]) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:value options:0 error:nil];
        canonicalString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    } else {
        canonicalString = [value stringify];
    }
    
    return stringOrEmpty(canonicalString);
}

FORCE_INLINE NSArray<ALNSURLQueryItem *> *queryItemsFromQueryStirng(NSString *urlencodedQuery) {
    return [[[urlencodedQuery componentsSeparatedByString:@"&"] bk_select:^BOOL(NSString *itemString) {
        return castToTypeOrNil(itemString, NSString).length > 0;
    }] bk_map:^ALNSURLQueryItem *(NSString *itemString) {
        NSArray *pairs = [castToTypeOrNil(itemString, NSString) componentsSeparatedByString:@"="];
        return [ALNSURLQueryItem queryItemWithName:[pairs.firstObject ?: @"" stringByURLDecoding]
                                             value:[[pairs objectAtIndexSafely:1] stringByURLDecoding]];
    }];
}

//FORCE_INLINE void addOrReplaceObjectInArray(NSMutableArray *array, id object, BOOL (^matchBlock)(id existedObject)) {
//    NSUInteger index = [array indexOfObjectPassingTest:^BOOL(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
//        BOOL found = NO;
//        if (matchBlock && matchBlock(obj)) {
//            found = YES;
//        }
//        *stop = found;
//        return found;
//    }];
//    if (index == NSNotFound) {
//        if (object != nil) {
//            [array addObject:object];
//        }
//    } else if (object == nil) {
//        [array removeObjectAtIndex:index];
//    } else {
//        [array replaceObjectAtIndex:index withObject:object];
//    }
//}

FORCE_INLINE void addOrReplaceQueryItems(NSMutableArray<ALNSURLQueryItem *> *originalItems,
                                         NSArray<ALNSURLQueryItem *> *addingItems) {
    ALOrderedMap<NSString *, NSString *> *orderedMap = [ALOrderedMap orderedMap];
    [[originalItems arrayByAddingObjectsFromArray:addingItems] bk_each:^(ALNSURLQueryItem *item) {
        [orderedMap setObject:item.value forKey:item.name];
    }];

    [originalItems removeAllObjects];
    [orderedMap
        enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSString *_Nonnull obj, BOOL *_Nonnull stop) {
            [originalItems addObject:[ALNSURLQueryItem queryItemWithName:key rawValue:obj]];
        }];
    //
    //
    //
    //    NSMutableArray *appendingItems = [NSMutableArray arrayWithCapacity:addingItems.count];
    //    [addingItems bk_each:^(ALNSURLQueryItem *item) {
    //        addOrReplaceObjectInArray(appendingItems, item, ^BOOL(ALNSURLQueryItem *existedObject) {
    //            return stringEquals(castToTypeOrNil(item, ALNSURLQueryItem).name,
    //                                castToTypeOrNil(existedObject, ALNSURLQueryItem).name);
    //        });
    //    }];
    //
    //    [appendingItems bk_each:^(ALNSURLQueryItem *item) {
    //        NSUInteger lastFoundIndex = NSNotFound;
    //        while (YES) {
    //            NSUInteger index = [originalItems indexOfObjectPassingTest:^BOOL(ALNSURLQueryItem *_Nonnull
    //            resultItem,
    //                                                                             NSUInteger idx, BOOL *_Nonnull stop)
    //                                                                             {
    //                BOOL found = stringEquals(castToTypeOrNil(item, ALNSURLQueryItem).name,
    //                                          castToTypeOrNil(resultItem, ALNSURLQueryItem).name);
    //                if (lastFoundIndex != NSNotFound) {
    //                    found = found && (idx > lastFoundIndex);
    //                }
    //
    //                *stop = found;
    //                return found;
    //            }];
    //
    //            if (index == NSNotFound) {
    //                if (lastFoundIndex == NSNotFound) {
    //                    [originalItems addObject:item];
    //                }
    //                break;
    //            } else {
    //                if (lastFoundIndex == NSNotFound) {
    //                    [originalItems replaceObjectAtIndex:index withObject:item];
    //                } else {
    //                    [originalItems removeObjectAtIndex:index];
    //                }
    //                lastFoundIndex = index;
    //            }
    //        }
    //    }];
}

FORCE_INLINE NSString *queryStringFromQueryItems(NSArray<ALNSURLQueryItem *> *items) {
    return [[items bk_map:^NSString *(ALNSURLQueryItem *item) {
        NSString *string = [item.name stringByURLEncoding];
        if (item.value != nil) {
            string = [string stringByAppendingFormat:@"=%@", [item.value stringByURLEncoding]];
        }
        return string;
    }] componentsJoinedByString:@"&"];
}

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0 || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_10
@implementation ALNSURLQueryItem

@synthesize name  = _name;
@synthesize value = _value;

+ (instancetype)queryItemWithName:(NSString *)name value:(NSString *)value {
    if (!([name isKindOfClass:[NSString class]] && (value == nil || [value isKindOfClass:[NSString class]]))) {
        NSAssert(NO, @"param 'name' and 'value' must be kind of NSString");
        return nil;
    }
    ALNSURLQueryItem *item = [[ALNSURLQueryItem alloc] init];
    item->_name  = [name copy];
    item->_value = [value copy];
    return item;
}

+ (instancetype)queryItemWithName:(NSString *)name rawValue:(nullable id)rawValue {
    return [self queryItemWithName:URLParamStringify(name) value:URLParamStringify(rawValue)];
}

- (NSString *)description {
    return [[super description] stringByAppendingFormat:@" name:%@; value: %@", self.name, self.value];
}

@end

#else

@implementation NSURLQueryItem(ALURLHelper)

+ (instancetype)queryItemWithName:(NSString *)name rawValue:(nullable id)rawValue {
    return [self queryItemWithName:URLParamStringify(name) value:URLParamStringify(rawValue)];
}

@end

#endif


@implementation NSURL (ALURLHelper)

- (NSURL * (^)(NSString *name, id value))SET_QUERY_ITEM {
    return ^NSURL *(NSString *name, id value) {
        return [self URLByAppendingQueryItems:@[ queryItem(name, value) ] replace:YES];
    };
}

- (NSURL *)URLBySettingQueryParamsOfDictionary:(NSDictionary<NSString *, id> *)itemDict {
    return [self URLByAppendingQueryItems:[itemDict.allKeys bk_map:^ALNSURLQueryItem *(NSString *name) {
                     return queryItem(name, itemDict[name]);
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
         return [ALNSURLQueryItem queryItemWithName:name rawValue:itemsDict[name]];
     }]);
}

@end

@implementation NSString (ALURLHelper)

- (NSArray<ALNSURLQueryItem *> *)queryItems {
    NSString *queryString = self;
    //FIXME: if a string is the query string of the URL, [NSURLComponents componentsWithString:] will treat it as 'path' not 'query'. Anyone could help me to solve it?
//    NSURLComponents *comps = [NSURLComponents componentsWithString:self];
//    if (comps) {
//        queryString = comps.query;
//    }
    return queryItemsFromQueryStirng(queryString);
}

- (NSDictionary<NSString *, NSString *> *)queryItemsDictionary {
    NSArray *items = [self queryItems];
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
        return [self URLStringByAppendingQueryItems:@[queryItem(name, value)] replace:YES];
    };
}

- (NSString *)URLStringBySettingQueryParamsOfDictionary:(NSDictionary<NSString *, id> *)itemDict {
    return [self URLStringByAppendingQueryItems:[itemDict.allKeys bk_map:^ALNSURLQueryItem *(NSString *name) {
                     return queryItem(name, itemDict[name]);
                 }]
                                        replace:YES];
}

- (NSString *)URLStringByAppendingQueryItems:(NSArray<ALNSURLQueryItem *> *)items replace:(BOOL)replace {
    NSURL *URL = [NSURL URLWithString:self];
    if (URL != nil) {
        return [URL URLByAppendingQueryItems:items replace:replace].absoluteString;
    }

    NSRange queryStringRange = [self URLQueryStringRange];
    NSString *query = [self substringWithRangeSafety:queryStringRange];

    NSArray<ALNSURLQueryItem *> *queryItems = nil;
    if (!isEmptyString(query)) {
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
    
    if (isEmptyString(query)) {
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


- (NSString *)stringByURLEncoding {
    NSString *resultStr = self;
    
    CFStringRef originalString = (__bridge CFStringRef) self;
    CFStringRef leaveUnescaped = CFSTR(" ");
    CFStringRef forceEscaped   = CFSTR("!*'();:@&=+$,/?%#[]");
    
    CFStringRef escapedStr;
    escapedStr = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, originalString, leaveUnescaped,
                                                         forceEscaped, kCFStringEncodingUTF8);
    
    if (escapedStr) {
        NSMutableString *mutableStr = [NSMutableString stringWithString:(__bridge NSString *) escapedStr];
        CFRelease(escapedStr);
        
        // replace spaces with plusses
        [mutableStr replaceOccurrencesOfString:@" "
                                    withString:@"%20"
                                       options:0
                                         range:NSMakeRange(0, [mutableStr length])];
        resultStr = mutableStr;
    }
    return resultStr;
}

- (NSString *)stringByURLDecoding {
    NSString *result = [self stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    result           = [result stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return result;
}

@end
