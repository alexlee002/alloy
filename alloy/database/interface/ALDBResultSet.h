//
//  ALDBResultSet.h
//  alloy
//
//  Created by Alex Lee on 02/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALDBTypeDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface ALDBResultSet : NSObject

- (BOOL)hasError;
- (nullable NSError *)lastError;

- (NSInteger)columnsCount;
- (nullable NSString *)columnNameAtIndex:(NSInteger)index;
- (NSInteger)columnIndexForName:(NSString *)name;
- (ALDBColumnType)columnTypeAtIndex:(NSInteger)index;

- (nullable NSString *)sql;
- (nullable NSString *)expandedSQL;

- (BOOL)next;

- (NSInteger)integetForColumn:(NSString *)columnName;
- (NSInteger)integerForColumnIndex:(NSInteger)index;

- (double)doubleForColumn:(NSString *)columnName;
- (double)doubleForColumnIndex:(NSInteger)index;

- (BOOL)boolForColumn:(NSString *)columnName;
- (BOOL)boolForColumnIndex:(NSInteger)index;

- (nullable NSString *)stringForColumn:(NSString *)columnName;
- (nullable NSString *)stringForColumnIndex:(NSInteger)index;

- (nullable NSData *)dataForColumn:(NSString *)columnName;
- (nullable NSData *)dataForColumnIndex:(NSInteger)index;

- (nullable NSDate *)dateForColumn:(NSString *)columnName;
- (nullable NSDate *)dateForColumnIndex:(NSInteger)index;

- (nullable id)objectAtIndexedSubscript:(NSInteger)index;
- (nullable id)objectForKeyedSubscript:(NSString *)columnName;
@end

NS_ASSUME_NONNULL_END
