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

- (void)setObject:(ObjectType)object forKey:(KeyType)key;
- (nullable ObjectType)removeObjectForKey:(KeyType)key;

- (nullable ObjectType)objectForKey:(KeyType)key;
- (BOOL)containsKey:(KeyType)key;

- (NSArray<KeyType> *)orderedKeys;
- (NSArray<ObjectType> *)orderedObjects;
@end

NS_ASSUME_NONNULL_END
