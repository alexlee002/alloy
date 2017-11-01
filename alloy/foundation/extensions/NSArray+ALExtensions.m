//
//  NSArray+ALExtensions.m
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "NSArray+ALExtensions.h"
#import "ALLogger.h"

@implementation NSArray (ALExtensions)

- (NSArray *)al_subarrayWithRange:(NSRange)range {
    if (range.location < self.count) {
        if (range.location + range.length < self.count) {
            return [self subarrayWithRange:range];
        } else {
            return [self al_subarrayFromIndex:range.location];
        }
    } else {
        return nil;
    }
}

- (NSArray *)al_subarrayFromIndex:(NSInteger)from length:(NSInteger)length {
    from = from < 0 ? MAX(0, (NSInteger) self.count + from) : from;
    if (from >= self.count) {
        return nil;
    }
    
    if (length < 0) {
        NSInteger end = (NSInteger)self.count + length;
        if (end < from) {
            return nil;
        }
        return [self subarrayWithRange:NSMakeRange(from, end - from)];
    }
    
    return [self subarrayWithRange:NSMakeRange(from, MIN(length, self.count - from))];
}

- (NSArray *)al_subarrayFromIndex:(NSInteger)index {
    index = index < 0 ? MAX(0, (NSInteger) self.count + index) : index;
    if (index < self.count) {
        return [self subarrayWithRange:NSMakeRange(index, self.count - index)];
    }
    return nil;
}

- (NSArray *)al_subarrayToIndex:(NSInteger)to {
    if (to < 0) {
        NSUInteger index = ABS(to);
        if (index < self.count) {
            return [self subarrayWithRange:NSMakeRange(0, self.count - index)];
        }
        return nil;
    }
    
    return [self subarrayWithRange:NSMakeRange(0, MIN(to, self.count))];
}

- (NSArray *)al_subarrayFromIndexSafely:(NSUInteger)index {
    if (index < self.count) {
        return [self subarrayWithRange:NSMakeRange(index, self.count - index)];
    }
    return nil;
}

- (NSArray *)al_subarrayToIndexSafely:(NSUInteger)index {
    return [self subarrayWithRange:NSMakeRange(0, MIN(index, self.count))];
}

- (nullable id)al_objectAtIndexSafely:(NSInteger)index {
    if (index < self.count) {
        return [self objectAtIndex:index];
    }
    return nil;
}
@end
