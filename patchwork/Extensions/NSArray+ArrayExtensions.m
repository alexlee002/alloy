//
//  NSArray+ArrayExtensions.m
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "NSArray+ArrayExtensions.h"

@implementation NSArray (ALExtensions)

- (nullable NSArray *)al_subarrayFromIndex:(NSInteger)from length:(NSInteger)length {
    NSUInteger start = from > 0 ? from : self.count + from;
    NSUInteger end = length > 0 ? start + length : self.count + length;
    return [[self al_subarrayFromIndex:start] al_subarrayToIndex:end];
}

- (nullable NSArray *)al_subarrayFromIndex:(NSUInteger)index {
    NSParameterAssert(index < self.count);
    
    if (index < self.count) {
        return [self subarrayWithRange:NSMakeRange(index, self.count - index)];
    }
    return nil;
}

- (nullable NSArray *)al_subarrayToIndex:(NSUInteger)index {
    NSParameterAssert(index < self.count);
    
    return [self subarrayWithRange:NSMakeRange(0, MIN(index, self.count))];
}

- (nullable id)al_objectAtIndexSafely:(NSUInteger)index {
    NSParameterAssert(index < self.count);
    
    if (index < self.count) {
        return [self objectAtIndex:index];
    }
    return nil;
}

- (nullable id)al_objectAtIndexedSubscriptSafely:(NSUInteger)idx {
    NSParameterAssert(idx < self.count);
    
    if (idx < self.count) {
        return [self objectAtIndexedSubscript:idx];
    }
    return nil;
}
@end
