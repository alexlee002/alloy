//
//  NSArray+ALExtensions.h
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray<T> (ALExtensions)

- (NSArray<T> *)al_subarrayWithRange:(NSRange)range;

/**
 *  return a sub-array;
 *  example:
 *      NSArray<NSString *> *array = @[@"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7"];
 *      [array al_subarrayFromIndex:5]   => @[@"5", @"6", @"7"]
 *      [array al_subarrayFromIndex:-3]  => @[@"5", @"6", @"7"]
 *      [array al_subarrayFromIndex:10]  => nil
 *      [array al_subarrayFromIndex:-10] => array
 *
 *  @param   index   Refers to the position of the array to start cutting.
                     A positive number : Start at the specified position in the array.
                     A negative number : Start at a specified position from the end of the array.
 *  @return return sub-array or nil if index > self.count.
 */
- (nullable NSArray<T> *)al_subarrayFromIndex:(NSInteger)index;

/**
 *  return a sub-array;
 *  example:
 *      NSArray<NSString *> *array = @[@"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7"];
 *      [array al_subarrayToIndex:3]   => @[@"0", @"1", @"2"]
 *      [array al_subarrayToIndex:-5]  => @[@"0", @"1", @"2"]
 *      [array al_subarrayToIndex:-10] => nil
 *      [array al_subarrayToIndex:10]  => array
 *
 *  @param   index   Refers to the position of the array to start cutting.
 *                   A positive number : Start at the specified position in the array.
 *                   A negative number : Start at a specified position from the end of the array.
 *  @return the sub-array or nil if index < 0 and ABS(index) > self.count.
 */
- (nullable NSArray<T> *)al_subarrayToIndex:(NSInteger)index;

/**
 *  return a sub-array from an array
 *  example:
 *      NSArray<NSString *> *array = @[@"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7"];
 *      [array al_subarrayFromIndex:3 length:3]   => @[@"3", @"4", @"5"]
 *      [array al_subarrayFromIndex:-5 length:3]  => @[@"3", @"4", @"5"]
 *      [array al_subarrayFromIndex:-5 length:-2] => @[@"3", @"4", @"5"]
 *      [array al_subarrayFromIndex:3 length:-2]  => @[@"3", @"4", @"5"]
 *
 *      [array al_subarrayFromIndex:10 length:3]    => nil
 *      [array al_subarrayFromIndex:10 length:-10]  => nil
 *      [array al_subarrayFromIndex:-10 length:-10] => nil
 *
 *      [array al_subarrayFromIndex:-5 length:10]  => @[@"3", @"4", @"5", @"6", @"7"]
 *      [array al_subarrayFromIndex:-10 length:10] => array
 *
 *  @param   from    Refers to the position of the array to start cutting.
                    A positive number : Start at the specified position in the array.
                    A negative number : Start at a specified position from the end of the array.
 *
 *  @param   length  Length of the string to cut from the array.
                    A positive number : Start at the specified position in the array.
                    A negative number : Start at a specified position from the end of the array.
 *  @return array silce.
 */
- (nullable NSArray<T> *)al_subarrayFromIndex:(NSInteger)from length:(NSInteger)length;

/**
 *  Returns the portion of array from the specified position;
 *
 *  @param  index   the position of the array to start cutting. if {index} is out of bounds, return nil;
 *
 *  @return nil if from is out of bounds, othwise return the substring.
 */
- (nullable NSArray<T> *)al_subarrayFromIndexSafely:(NSUInteger)index;

/**
 *  Returns the portion of array start from begining to the specified position;
 *
 *  @param  index    the position of the array to stop cutting. if {idex} is out of bounds, return the original array;
 *
 *  @return the substring or the original string.
 */
- (nullable NSArray<T> *)al_subarrayToIndexSafely:(NSUInteger)index;

/**
 *  return the item at specified position
 *
 *  @param  index the position of item
 *
 *  @return return nil if index out of bounds, otherwise return the item
 */
- (nullable T)al_objectAtIndexSafely:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
