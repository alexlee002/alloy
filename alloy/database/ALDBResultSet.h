//
//  ALDBResultSet.h
//  alloy
//
//  Created by Alex Lee on 17/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __cplusplus
#import "statement_recyclable.hpp"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface ALDBResultSet : NSObject

#ifdef __cplusplus
- (instancetype)initWithStatement:(const aldb::RecyclableStatement &)stmt;
#endif

- (NSInteger)columnCount;
- (nullable NSString *)columnNameAt:(NSInteger)index;
- (NSInteger)columnIndexForName:(NSString *)name;

- (BOOL)next;

- (NSInteger)integerValueForColumn:(NSString *)columnName;
- (NSInteger)integerValueForColumnIndex:(NSInteger)index;

- (double)doubleValueForColumn:(NSString *)columnName;
- (double)doubleValueForColumnIndex:(NSInteger)index;

- (BOOL)boolValueForColumn:(NSString *)columnName;
- (BOOL)boolValueForColumnIndex:(NSInteger)index;

- (nullable NSString *)stringValueForColumn:(NSString *)columnName;
- (nullable NSString *)stringValueForColumnIndex:(NSInteger)index;

- (nullable NSData *)dataForColumn:(NSString *)columnName;
- (nullable NSData *)dataForColumnIndex:(NSInteger)index;

- (nullable NSDate *)dateForColumn:(NSString *)columnName;
- (nullable NSDate *)dateForColumnIndex:(NSInteger)index;

- (nullable id)objectAtIndexedSubscript:(NSInteger)index;
- (nullable id)objectForKeyedSubscript:(NSString *)columnName;

@end

NS_ASSUME_NONNULL_END
