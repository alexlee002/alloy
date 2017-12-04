//
//  URLHelper.m
//  patchwork
//
//  Created by Alex Lee on 5/27/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALURLHelper.h"
#import "BlocksKit.h"
#import "NSArray+ALExtensions.h"
#import "ALMacros.h"
#import "NSString+ALHelper.h"
#import "ALOrderedMap.h"
#import <objc/message.h>


AL_FORCE_INLINE NSString *_Nullable ALURLParamStringify(id _Nullable value) {
    NSString *canonicalString = al_stringValue(value);
    if (canonicalString == nil && [NSJSONSerialization isValidJSONObject:value]) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:value options:0 error:nil];
        canonicalString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return canonicalString;
}

static AL_FORCE_INLINE void addOrReplaceQueryItems(NSMutableArray<ALURLQueryItem *> *targetItems,
                                                   NSArray<ALURLQueryItem *> *appendingItems) {
    ALOrderedMap<NSString *, NSString *> *orderedMap = [ALOrderedMap orderedMap];
    [[targetItems arrayByAddingObjectsFromArray:appendingItems] bk_each:^(ALURLQueryItem *item) {
        [orderedMap setObject:item.value forKey:item.name];
    }];

    [targetItems removeAllObjects];
    [orderedMap
        enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSString *_Nonnull obj, BOOL *_Nonnull stop) {
            [targetItems addObject:[ALURLQueryItem queryItemWithName:key value:obj]];
        }];
}

static AL_FORCE_INLINE NSArray<ALURLQueryItem *> *queryItemsArrayFromDictionary(NSDictionary<NSString *, id> *itemDict,
                                                                                BOOL encoded) {
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:itemDict.count];
    [itemDict bk_each:^(NSString *name, id value) {
        if (encoded) {
            ALCParameterAssert(value == nil || [value isKindOfClass:NSString.class]);
            [items addObject:[ALURLQueryItem queryItemWithPercentEncodedName:name
                                                         percentEncodedValue:ALCastToTypeOrNil(value, NSString)]];
        } else {
            [items addObject:[ALURLQueryItem queryItemWithName:name rawValue:value]];
        }
    }];
    return items;
}

#pragma mark -
@implementation ALURLQueryItem

+ (instancetype)queryItemWithItem:(NSURLQueryItem *)src percentEncoded:(BOOL)encoded {
    if (encoded) {
        return [self queryItemWithPercentEncodedName:src.name percentEncodedValue:src.value];
    }
    return [self queryItemWithName:src.name value:src.value];
}

+ (instancetype)queryItemWithName:(NSString *)name rawValue:(nullable id)rawValue {
    return [self queryItemWithName:ALURLParamStringify(name) value:ALURLParamStringify(rawValue)];
}

+ (instancetype)queryItemWithPercentEncodedName:(NSString *)name percentEncodedValue:(nullable NSString *)value {
    al_guard_or_return([name isKindOfClass:NSString.class] && (value == nil || [value isKindOfClass:NSString.class]),
                       nil);
    ALURLQueryItem *item       = [[ALURLQueryItem alloc] init];
    item->_percentEncodedName  = name;
    item->_percentEncodedValue = value;
    return item;
}

- (NSString *)name {
    NSString *result = super.name;
    if (result == nil) {
        result = [_percentEncodedName al_stringByURLDecoding];
    }
    return result;
}

- (NSString *)value {
    NSString *result = super.value;
    if (result == nil) {
        result = [_percentEncodedValue al_stringByURLDecoding];
    }
    return result;
}

@synthesize percentEncodedName = _percentEncodedName;
- (NSString *)percentEncodedName {
    NSString *result = _percentEncodedName;
    if (result == nil) {
        result = [self.name al_stringByURLEncodingAs:ALURLComponentQueryItem];
    }
    return result;
}

@synthesize percentEncodedValue = _percentEncodedValue;
- (NSString *)percentEncodedValue {
    NSString *result = _percentEncodedValue;
    if (result == nil) {
        result = [self.value al_stringByURLEncodingAs:ALURLComponentQueryItem];
    }
    return result;
}

- (id)copyWithZone:(NSZone *)zone {
    ALURLQueryItem *item     = [super copyWithZone:zone];
    item->_percentEncodedName  = [_percentEncodedName copy];
    item->_percentEncodedValue = [_percentEncodedValue copy];
    return item;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.percentEncodedName forKey:al_keypath(self.percentEncodedName)];
    [aCoder encodeObject:self.percentEncodedValue forKey:al_keypath(self.percentEncodedValue)];
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        if ([self.class supportsSecureCoding]) {
            _percentEncodedName =
                [aDecoder decodeObjectOfClass:[NSString class] forKey:al_keypath(self.percentEncodedName)];
            _percentEncodedValue =
                [aDecoder decodeObjectOfClass:[NSString class] forKey:al_keypath(self.percentEncodedValue)];
        } else {
            _percentEncodedName =
                ALCastToTypeOrNil([aDecoder decodeObjectForKey:al_keypath(self.percentEncodedName)], NSString);
            _percentEncodedValue =
                ALCastToTypeOrNil([aDecoder decodeObjectForKey:al_keypath(self.percentEncodedValue)], NSString);
        }
    }
    return self;
}

@end

#pragma mark -
@implementation NSURLComponents (ALCompatible)
- (void)al_setQueryItems:(NSArray<ALURLQueryItem *> *)queryItems {
    if ([self respondsToSelector:@selector(setQueryItems:)]) {
        // API_AVAILABLE(macos(10.10), ios(8.0), watchos(2.0), tvos(9.0));
        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) self, @selector(setQueryItems:), (id) queryItems);
    } else {
        NSString *query = [queryItems bk_reduce:[@"" mutableCopy]
                                      withBlock:^NSMutableString *(NSMutableString *query, ALURLQueryItem *item) {
                                          al_guard_or_return([item isKindOfClass:ALURLQueryItem.class], query);
                                          NSString *str = item.percentEncodedName;
                                          if (str != nil) {
                                              if (query.length > 0) {
                                                  [query appendString:@"&"];
                                              }
                                              [query appendString:str];

                                              str = item.percentEncodedValue;
                                              if (str != nil) {
                                                  [query appendFormat:@"=%@", str];
                                              }
                                          }
                                          return query;
                                      }];
        self.percentEncodedQuery = query;
    }
}

- (NSArray<ALURLQueryItem *> *)al_queryItems {
    if ([self respondsToSelector:@selector(queryItems)]) {
        NSArray *NSItems = ((id(*)(id, SEL))(void *) objc_msgSend)((id) self, @selector(queryItems));
        return [NSItems bk_map:^ALURLQueryItem *(NSURLQueryItem *obj) {
            return [ALURLQueryItem queryItemWithName:obj.name value:obj.value];
        }];
    } else {
        NSString *queryString = self.percentEncodedQuery;
        return [[queryString componentsSeparatedByString:@"&"] bk_map:^ALURLQueryItem *(NSString *item) {
            NSUInteger pos = [item rangeOfString:@"="].location;
            if (pos == NSNotFound) {
                return [ALURLQueryItem queryItemWithPercentEncodedName:item percentEncodedValue:nil];
            }
            return [ALURLQueryItem queryItemWithPercentEncodedName:[item substringToIndex:pos]
                                               percentEncodedValue:[item substringFromIndex:pos + 1]];
        }];
    }
}
@end

#pragma mark -

@implementation NSURL (ALURLHelper)

- (NSURL * (^)(NSString *name, id value))AL_SET_QUERY_ITEM {
    return ^NSURL *(NSString *name, id value) {
        return [self al_URLByAppendingQueryItems:@[ [ALURLQueryItem queryItemWithName:name rawValue:value] ]
                                     deduplicate:YES];
    };
}

- (NSURL *)al_URLByAppendingQueryItems:(NSArray<ALURLQueryItem *> *)queryItems deduplicate:(BOOL)replaceExisted {
    NSURLComponents *comps = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:YES];
    NSArray<ALURLQueryItem *> *originalItems = [comps al_queryItems];
    if (replaceExisted) {
        NSMutableArray<ALURLQueryItem *> *resultItems =
            originalItems == nil ? [NSMutableArray array] : [originalItems mutableCopy];
        addOrReplaceQueryItems(resultItems, queryItems);
        originalItems = resultItems;
    } else {
        originalItems = (originalItems == nil) ? queryItems : [originalItems arrayByAddingObjectsFromArray:queryItems];
    }

    comps.al_queryItems = originalItems;
    return comps.URL;
}

- (NSURL *)al_URLByAppendingQueryItemsWithDictionary:(NSDictionary<NSString *, id> *)itemDict
                                      percentEncoded:(BOOL)encoded
                                         deduplicate:(BOOL)replaceExisted {
    NSArray *items = queryItemsArrayFromDictionary(itemDict, encoded);
    return [self al_URLByAppendingQueryItems:items deduplicate:replaceExisted];
}

- (NSArray<ALURLQueryItem *> *)al_queryItems {
    return [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:YES].al_queryItems;
}

- (NSURLComponents *)al_URLComponentByResolvingAgainstBaseURL:(BOOL)resolve {
    return [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:resolve];
}

@end

#pragma mark -

@implementation NSString (ALURLHelper)

- (NSString * (^)(NSString *name, id value))AL_SET_QUERY_ITEM {
    return ^NSString *(NSString *name, id value) {
        return [self al_URLStringByAppendingQueryItems:@[ [ALURLQueryItem queryItemWithName:name rawValue:value] ]
                                           deduplicate:YES];
    };
}

- (NSString *)al_URLStringByAppendingQueryItems:(NSArray<ALURLQueryItem *> *)queryItems deduplicate:(BOOL)replace {
    NSURL *URL = [NSURL URLWithString:self];
    al_guard_or_return(URL != nil, nil);

    return [URL al_URLByAppendingQueryItems:queryItems deduplicate:replace].absoluteString;
}

- (NSString *)al_URLStringByAppendingQueryItemsWithDictionary:(NSDictionary<NSString *, id> *)itemDict
                                               percentEncoded:(BOOL)encoded
                                                  deduplicate:(BOOL)replace {
    NSURL *URL = [NSURL URLWithString:self];
    al_guard_or_return(URL != nil, nil);

    return [URL al_URLByAppendingQueryItemsWithDictionary:itemDict percentEncoded:encoded deduplicate:replace]
        .absoluteString;
}

- (NSString *)al_URLQueryStringByAppendingQueryItems:(NSArray<ALURLQueryItem *> *)queryItems
                                         deduplicate:(BOOL)replace {
    NSURLComponents *comps = [self al_URLComponentByResolvingAs:ALURLComponentQuery percentEncoded:YES];
    
    NSMutableArray *resultItems = [comps.al_queryItems mutableCopy] ?: [NSMutableArray array];
    addOrReplaceQueryItems(resultItems, queryItems);
    comps.al_queryItems = resultItems;
    return comps.percentEncodedQuery;

}

- (NSString *)al_URLQueryStringByAppendingQueryItemsWithDictionary:(NSDictionary<NSString *, id> *)itemDict
                                                    percentEncoded:(BOOL)encoded
                                                       deduplicate:(BOOL)replace {
    NSArray *items = queryItemsArrayFromDictionary(itemDict, encoded);
    return [self al_URLQueryStringByAppendingQueryItems:items deduplicate:replace];
}

- (NSRange)al_URLQueryStringRange {
    
    NSRange queryStringRange = [self al_URLComponents].rangeOfQuery;
    if (queryStringRange.location != NSNotFound) {
        return queryStringRange;
    }
    
    /// @see RFC 1808: https://www.ietf.org/rfc/rfc1808.txt
    /// URL Components: <scheme>://<net_loc>/<path>;<params>?<query>#<fragment>
    /// @see https://opensource.apple.com/source/CF/CF-635/CFURL.c.auto.html  function: _parseComponents()
    NSUInteger queryEnd = [self rangeOfString:@"#"].location;
    if (queryEnd == NSNotFound) {
        queryEnd = self.length;
    }
    
    NSUInteger queryStart = [self rangeOfString:@"?" options:0 range:NSMakeRange(0, queryEnd)].location;
//    if (queryStart == NSNotFound) {
//        // eg: abc.com/&ab=12, need test?
//        queryStart = [self rangeOfString:@"&"].location;
//    }
    if (queryStart != NSNotFound) {
        return NSMakeRange(queryStart + 1, queryEnd - queryEnd - 1);
    }
    return NSMakeRange(NSNotFound, 0);
}

- (NSArray<ALURLQueryItem *> *)al_URLQueryItems {
    NSString *queryString = self;
    NSRange queryRange    = [self al_URLQueryStringRange];
    if (queryRange.location != NSNotFound) {
        queryString = [self substringWithRange:queryRange];
    }

    return [queryString al_URLComponentByResolvingAs:ALURLComponentQuery percentEncoded:YES].al_queryItems;
}

- (NSDictionary<NSString *, NSString *> *)al_URLQueryItemsDictionary {
    NSArray *items = [self al_URLQueryItems];
    if (items == nil) {
        return nil;
    }
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [items bk_each:^(ALURLQueryItem *item) {
        dict[item.name] = al_wrapNil(item.value);
    }];
    return [dict copy];

}

- (NSString *)al_stringByURLEncodingAs:(ALURLComponent)component {
    switch (component) {
        case ALURLComponentQueryItem:
            return [self
                stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet al_URLQueryItemAllowedCharacterSet]];
        case ALURLComponentQuery:
            return
                [self stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        case ALURLComponentPath:
        case ALURLComponentParam:
            return
                [self stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
        case ALURLComponentFragment:
            return [self
                stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
        case ALURLComponentHost:
            return
                [self stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
        case ALURLComponentUser:
            return
                [self stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLUserAllowedCharacterSet]];
        case ALURLComponentPassword:
            return [self
                stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPasswordAllowedCharacterSet]];
         
        // ignore compoments
        case ALURLComponentPort:
        case ALURLComponentScheme:
            break;
    }
    return self;
}

- (NSString *)al_stringByURLDecoding {
    return [self stringByRemovingPercentEncoding];
}

- (nullable NSURL *)al_URL {
    return [NSURL URLWithString:self];
}

- (nullable NSURL *)al_URLRelativeToURL:(NSURL *)baseURL {
    return [NSURL URLWithString:self relativeToURL:baseURL];
}

- (nullable NSURLComponents *)al_URLComponents {
    return [NSURLComponents componentsWithString:self];
}

- (NSURLComponents *)al_URLComponentByResolvingAs:(ALURLComponent)part percentEncoded:(BOOL)encoded {
    NSURLComponents *comps = [[NSURLComponents alloc] init];
    switch (part) {
        case ALURLComponentScheme:
            comps.scheme = self;
            break;
        case ALURLComponentUser:
            if (encoded) {
                comps.percentEncodedUser = self;
            } else {
                comps.user = self;
            }
            break;
        case ALURLComponentPassword:
            if (encoded) {
                comps.percentEncodedPassword = self;
            } else {
                comps.password = self;
            }
            break;
        case ALURLComponentHost:
            if (encoded) {
                comps.percentEncodedHost = self;
            } else {
                comps.host = self;
            }
            break;
        case ALURLComponentPort:
            comps.port = @([self intValue]);
            break;
        case ALURLComponentPath:
            if (encoded) {
                comps.percentEncodedPath = self;
            } else {
                comps.path = self;
            }
            break;
        case ALURLComponentQuery:
            if (encoded) {
                comps.percentEncodedQuery = self;
            } else {
                comps.query = self;
            }
            break;
        case ALURLComponentFragment:
            if (encoded) {
                comps.percentEncodedFragment = self;
            } else {
                comps.fragment = self;
            }
            break;
            
            //ignore components
        case ALURLComponentParam:
        case ALURLComponentQueryItem:
            return nil;
    }
    return comps;
}
@end

@implementation ALURLHelper

+ (NSString *)queryStringWithItems:(NSArray<ALURLQueryItem *> *)queryItems {
    NSURLComponents *comps = [[NSURLComponents alloc] init];
    comps.al_queryItems = queryItems;
    return comps.percentEncodedQuery;

}

+ (NSString *)queryStringWithDictionary:(NSDictionary<NSString *, id> *)itemDict percentEncoded:(BOOL)encoded {
    NSArray *items = queryItemsArrayFromDictionary(itemDict, encoded);
    return [self queryStringWithItems:items];
}

@end

@implementation NSCharacterSet (ALURLHelper)

+ (NSCharacterSet *)al_URLQueryItemAllowedCharacterSet {
    static NSCharacterSet *allowedCharset = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        /// @link   https://github.com/apple/swift-corelibs-foundation/blob/master/CoreFoundation/URL.subproj/CFURLComponents.c
        /// @see    _CFURLComponentsSetQueryItems()
        ///
        /// also, @see RFC 3986 - Section 3.4. It is recommended that both the ? and / are not percent escaped in query string parameters.
        /// @link https://tools.ietf.org/html/rfc3986#section-3.4
        /// @link https://github.com/Alamofire/Alamofire/issues/908
        NSMutableCharacterSet *charset = [NSCharacterSet.URLQueryAllowedCharacterSet mutableCopy];
        [charset removeCharactersInString:@"&="];
        allowedCharset = [charset copy];
    });
    
    return allowedCharset;
}
@end
