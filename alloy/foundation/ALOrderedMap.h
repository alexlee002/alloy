//
//  ALOrderedMap.h
//  patchwork
//
//  Created by Alex Lee on 27/10/2016.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ALOrderedMap<__covariant KeyType, __covariant ObjectType> : NSObject

+ (instancetype)orderedMap;

- (void)setObject:(ObjectType)object forKey:(KeyType)key;
- (nullable ObjectType)removeObjectForKey:(KeyType)key;

- (nullable ObjectType)objectForKey:(KeyType)key;
- (BOOL)containsKey:(KeyType)key;
- (BOOL)containsObject:(ObjectType)obj;

- (NSArray<KeyType> *)orderedKeys;
- (NSArray<ObjectType> *)orderedObjects;

- (void)enumerateKeysAndObjectsUsingBlock:(void(NS_NOESCAPE ^)(KeyType key, ObjectType obj, BOOL *stop))block;
- (void)enumerateKeysAndObjectsWithOptions:(NSEnumerationOptions)opts
                                usingBlock:(void(NS_NOESCAPE ^)(KeyType key, ObjectType obj, BOOL *stop))block;

@end

NS_ASSUME_NONNULL_END
