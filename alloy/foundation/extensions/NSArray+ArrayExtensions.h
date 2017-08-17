//
//  NSArray+ArrayExtensions.h
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray<T> (ALExtensions)

- (nullable NSArray<T> *)al_subarrayFromIndex:(NSUInteger)index;
- (nullable NSArray<T> *)al_subarrayToIndex:(NSUInteger)index;

/**
 * return a sub-array from an array
 *
 * @param   from    Refers to the position of the array to start cutting.
                    A positive number : Start at the specified position in the array.
                    A negative number : Start at a specified position from the end of the array.
 *
 * @param   length  Length of the string to cut from the array.
                    A positive number : Start at the specified position in the array.
                    A negative number : Start at a specified position from the end of the array.
 *
 */
- (nullable NSArray<T> *)al_subarrayFromIndex:(NSInteger)from length:(NSInteger)length;

- (nullable T)al_objectAtIndexSafely:(NSUInteger)index;
- (nullable T)al_objectAtIndexedSubscriptSafely:(NSUInteger)idx; // useless?

@end

NS_ASSUME_NONNULL_END
