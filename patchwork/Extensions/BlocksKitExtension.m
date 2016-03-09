//
//  NSArray+BlocksKitExtension.m
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "BlocksKitExtension.h"
#import "BLocksKit.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSArray (BlocksKitExtension)

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

@end

NS_ASSUME_NONNULL_END
