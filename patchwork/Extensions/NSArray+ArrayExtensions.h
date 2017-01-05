//
//  NSArray+ArrayExtensions.h
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray<T> (ArrayExtensions)

- (nullable NSArray<T> *)subarrayFromIndex:(NSUInteger)index;
- (nullable NSArray<T> *)subarrayToIndex:(NSUInteger)index;

- (nullable T)objectAtIndexSafely:(NSUInteger)index;
- (nullable T)objectAtIndexedSubscriptSafely:(NSUInteger)idx;

@end

NS_ASSUME_NONNULL_END
