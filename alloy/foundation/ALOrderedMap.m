//
//  ALOrderedMap.m
//  patchwork
//
//  Created by Alex Lee on 27/10/2016.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALOrderedMap.h"
#import "ALMacros.h"
#import "ALLock.h"


@interface ALOrderedMap<__covariant KeyType, __covariant ObjectType> ()
@property(PROP_ATOMIC_DEF, strong) NSMutableOrderedSet<KeyType>   *keys;
@property(PROP_ATOMIC_DEF, strong) NSMutableArray<ObjectType>     *objects;

@property(PROP_ATOMIC_DEF, strong) dispatch_semaphore_t            keyLock;

@end

@implementation ALOrderedMap

+ (instancetype)orderedMap {
    return [[self alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (self != nil) {
        _keys    = [NSMutableOrderedSet orderedSet];
        _objects = [NSMutableArray array];
        _keyLock = dispatch_semaphore_create(1);
    }
    return self;
}

- (void)setObject:(id)object forKey:(id)key {
    al_guard_or_return(key != nil, AL_VOID);
    
    if (object == nil) {
        [self removeObjectForKey:key];
        return;
    }

    with_gcd_semaphore(_keyLock, DISPATCH_TIME_FOREVER, ^{
        al_guard_or_return(self.keys.count == self.objects.count, AL_VOID);

        NSInteger index = [self.keys indexOfObject:key];
        if (index == NSNotFound) {
            [self.keys addObject:key];
            [self.objects addObject:object];
        } else {
            [self.objects replaceObjectAtIndex:index withObject:object];
        }
    });
}

- (id)__objectForKey:(id)key remove:(BOOL)remove {
    __block id obj = nil;
    with_gcd_semaphore(_keyLock, DISPATCH_TIME_FOREVER, ^{
        al_guard_or_return(self.keys.count == self.objects.count, AL_VOID);
        
        NSInteger index = [self.keys indexOfObject:key];
        if (index != NSNotFound) {
            obj = self.objects[index];
            if (remove) {
                [self.keys removeObjectAtIndex:index];
                [self.objects removeObjectAtIndex:index];
            }
        }
    });
    return obj;
}

- (id)removeObjectForKey:(id)key {
    return [self __objectForKey:key remove:YES];
}

- (nullable id)objectForKey:(id)key {
    return [self __objectForKey:key remove:NO];
}

- (BOOL)containsKey:(id)key {
    return [self.keys containsObject:key];
}

- (BOOL)containsObject:(id)obj {
    return [self.objects containsObject:obj];
}

- (NSArray *)orderedKeys {
    return self.keys.array;
}

- (NSArray *)orderedObjects {
    return [self.objects copy];
}

- (void)enumerateKeysAndObjectsUsingBlock:(void(NS_NOESCAPE ^)(id key, id obj, BOOL *stop))block {
    if (block == nil) {
        return;
    }
    with_gcd_semaphore(_keyLock, DISPATCH_TIME_FOREVER, ^{
        [self.keys enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull innerStop) {
            block(obj, self.objects[idx], innerStop);
        }];
    });
}

- (void)enumerateKeysAndObjectsWithOptions:(NSEnumerationOptions)opts
                                usingBlock:(void(NS_NOESCAPE ^)(id key, id obj, BOOL *stop))block {
    if (block == nil) {
        return;
    }
    with_gcd_semaphore(_keyLock, DISPATCH_TIME_FOREVER, ^{
        [self.keys enumerateObjectsWithOptions:opts
                                    usingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull innerStop) {
                                        block(obj, self.objects[idx], innerStop);
                                    }];
    });
}

@end
