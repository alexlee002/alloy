//
//  ALOrderedMap.m
//  patchwork
//
//  Created by Alex Lee on 27/10/2016.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALOrderedMap.h"
#import "UtilitiesHeader.h"

#define __AssertNotMatch()   NSAssert(NO, @"%@: keys are not match with values.", [super description]);


@interface ALOrderedMap<__covariant KeyType, __covariant ObjectType> ()
@property(PROP_ATOMIC_DEF, strong) NSMutableOrderedSet<KeyType>   *keys;
@property(PROP_ATOMIC_DEF, strong) NSMutableArray<ObjectType>     *objects;

@property(PROP_ATOMIC_DEF, strong) dispatch_semaphore_t            keyLock;

@end

@implementation ALOrderedMap

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
    if (key == nil) {
        NSAssert(NO, @"'key' can not be nil!");
        return;
    }
    if (object == nil) {
        [self removeObjectForKey:key];
        return;
    }
    dispatch_semaphore_wait(_keyLock, DISPATCH_TIME_FOREVER);
    
    if (self.keys.count != self.objects.count) {
        dispatch_semaphore_signal(_keyLock);
        __AssertNotMatch();
        return;
    }
    
    NSInteger index = [self.keys indexOfObject:key];
    if (index == NSNotFound) {
        [self.keys addObject:key];
        [self.objects addObject:object];
    } else {
        [self.objects replaceObjectAtIndex:index withObject:object];
    }
    dispatch_semaphore_signal(_keyLock);
}

- (id)__objectForKey:(id)key remove:(BOOL)remove {
    dispatch_semaphore_wait(_keyLock, DISPATCH_TIME_FOREVER);
    
    if (self.keys.count != self.objects.count) {
        dispatch_semaphore_signal(_keyLock);
        __AssertNotMatch();
        return nil;
    }
    
    NSInteger index = [self.keys indexOfObject:key];
    id obj = nil;
    if (index != NSNotFound) {
        obj = self.objects[index];
        if (remove) {
            [self.keys removeObjectAtIndex:index];
            [self.objects removeObjectAtIndex:index];
        }
    }
    dispatch_semaphore_signal(_keyLock);
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

- (NSArray *)orderedKeys {
    return self.keys.array;
}

- (NSArray *)orderedObjects {
    return [self.objects copy];
}

@end
