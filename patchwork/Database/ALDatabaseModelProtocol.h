//
//  ALDatabaseModelProtocol.h
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ALDBColumnInfo;
@class FMDatabase;
@protocol ALDatabaseModelProtocol <NSObject>

+ (BOOL)bindedToDatabase;

@optional
+ (NSString *)tableName;
+ (NSUInteger)tableVersion;
+ (NSString *)databasePath;


+ (nullable NSArray<ALDBColumnInfo *> *)columnDefines;
+ (nullable NSArray<NSString *> *)primaryKeys;
+ (nullable NSArray<NSArray<NSString *> *> *)uniqueKeys;
+ (nullable NSArray<NSArray<NSString *> *> *)indexKeys;

+ (nullable NSDictionary<NSString *, NSString *> *)modelCustomColumnNameMapper;

+ (BOOL)createTable:(FMDatabase *)db;
+ (BOOL)upgradeTableFromVersion:(NSInteger)fromVersion toVerion:(NSInteger)toVersion database:(FMDatabase *)db;
@end

NS_ASSUME_NONNULL_END
