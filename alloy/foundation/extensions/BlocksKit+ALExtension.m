//
//  BlocksKit+ALExtension.m
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "BlocksKit+ALExtension.h"
#import <BlocksKit/BlocksKit.h>

@implementation NSArray (ALBlocksKitExtension)

- (NSArray *)al_zip:(NSArray *)other, ... NS_REQUIRES_NIL_TERMINATION {
    NSMutableArray *arrays = [NSMutableArray arrayWithObject:self];
    va_list args;
    va_start(args, other);
    NSUInteger minLength = self.count;
    for (NSArray *item = other; item != nil; item = va_arg(args, id)) {
        if (![item isKindOfClass:[NSArray class]]) {
            item = @[ item ];
        }
        [arrays addObject:item];
        minLength = MIN(minLength, item.count);
    }
    va_end(args);
    
    NSMutableArray *newArray = [NSMutableArray arrayWithCapacity:minLength];
    for (NSUInteger i = 0; i < minLength; ++i) {
        [newArray addObject:[arrays bk_map:^id(NSArray  *subArray) {
            return subArray[i];
        }]];
    }
    return [newArray copy];
}

- (NSArray *)al_flatten {
    NSMutableArray *flattenArray = [NSMutableArray array];
    [self bk_each:^(id obj) {
        if ([obj isKindOfClass:[NSArray class]]) {
            [flattenArray addObjectsFromArray:obj];
        } else {
            [flattenArray addObject:obj];
        }
    }];
    return [flattenArray copy];
}

- (NSArray *)al_flatMap:(id(^)(id obj))block {
    NSParameterAssert(block != nil);
    
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:self.count];
    
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id value = block(obj);
        if (value != nil) {
            [result addObject:value];
        }
    }];
    
    return result;
}

@end

@implementation NSMutableArray (ALBlocksKitExtension)

- (void)al_performFlatMap:(id(^)(id obj))block {
    NSParameterAssert(block != nil);
    NSMutableArray *new = [NSMutableArray arrayWithCapacity:self.count];
    
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id value = block(obj);
        if (value != nil) {
            [new addObject:value];
        }
    }];
    
    [self setArray:new];
}
@end

#pragma mark - NSDictionary
@implementation NSDictionary (ALBlocksKitExtension)

- (NSDictionary *)al_flatMap:(id (^)(id key, id obj))block {
    NSParameterAssert(block != nil);
    
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:self.count];
    
    [self bk_each:^(id key, id obj) {
        id value = block(key, obj);
        if (value != nil) {
            result[key] = value;
        }
    }];
    
    return result;
}

@end

@implementation NSMutableDictionary (ALBlocksKitExtension)

- (void)al_performFlatMap:(id (^)(id key, id obj))block {
    NSParameterAssert(block != nil);
    
    NSMutableDictionary *new = [self mutableCopy];
    
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        id value = block(key, obj);
        if (value == nil) {
            [new removeObjectForKey:key];
        }
    }];
    
    [self setDictionary:new];
}

@end

#pragma mark - NSSet
@implementation NSSet (ALBlocksKitExtension)

- (NSSet *)al_flatMap:(id(^)(id obj))block {
    NSParameterAssert(block != nil);
    
    NSMutableSet *result = [NSMutableSet setWithCapacity:self.count];
    
    [self enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        id value = block(obj);
        if (value != nil) {
            [result addObject:value];
        }
    }];
    
    return result;
}

@end

@implementation NSMutableSet (ALBlocksKitExtension)

- (void)al_performFlatMap:(id(^)(id obj))block {
    NSParameterAssert(block != nil);
    
    NSMutableSet *new = [NSMutableSet setWithCapacity:self.count];
    
    [self enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        id value = block(obj);
        if (value != nil) {
            [new addObject:value];
        }
    }];
    
    [self setSet:new];
}

@end

#pragma mark - NSOrderedSet
@implementation NSOrderedSet (ALBlocksKitExtension)

- (NSOrderedSet *)al_flatMap:(id(^)(id obj))block {
    NSParameterAssert(block != nil);
    
    NSMutableOrderedSet *result = [NSMutableOrderedSet orderedSetWithCapacity:self.count];
    
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id value = block(obj);
        if (value != nil) {
            [result addObject:value];
        }
    }];
    
    return result;
}

@end

@implementation NSMutableOrderedSet (ALBlocksKitExtension)

- (void)al_performFlatMap:(id(^)(id obj))block {
    NSParameterAssert(block != nil);
    
    NSMutableIndexSet *newIndexes = [NSMutableIndexSet indexSet];
    NSMutableArray *newObjects = [NSMutableArray arrayWithCapacity:self.count];
    
    NSMutableIndexSet *removingIndexes = [NSMutableIndexSet indexSet];

    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id value = block(obj);
        if (value == nil) {
            [removingIndexes addIndex:idx];
        } else if (![value isEqual:obj]) {
            [newIndexes addIndex:idx];
            [newObjects addObject:obj];
        }
    }];

    [self replaceObjectsAtIndexes:newIndexes withObjects:newObjects];
    [self removeObjectsAtIndexes:removingIndexes];
}

@end

