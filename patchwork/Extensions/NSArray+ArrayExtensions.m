//
//  NSArray+ArrayExtensions.m
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "NSArray+ArrayExtensions.h"

@implementation NSArray (ArrayExtensions)

- (nullable NSArray *)subarrayFromIndex:(NSUInteger)index {
    if (index < self.count) {
        return [self subarrayWithRange:NSMakeRange(index, self.count - index)];
    }
    return nil;
}

- (nullable NSArray *)subarrayToIndex:(NSUInteger)index {
    return [self subarrayWithRange:NSMakeRange(0, MIN(index, self.count))];
}

- (nullable id)objectAtIndexSafely:(NSUInteger)index {
    if (index < self.count) {
        return [self objectAtIndex:index];
    }
    return nil;
}

- (nullable id)objectAtIndexedSubscriptSafely:(NSUInteger)idx {
    if (idx < self.count) {
        return [self objectAtIndexedSubscript:idx];
    }
    return nil;
}

@end
