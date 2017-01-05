//
//  ALDBMigrationHelper.h
//  patchwork
//
//  Created by Alex Lee on 04/01/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FMDB.h>
#import "ALModel.h"
#import "ALDBColumnInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface ALDBMigrationHelper : NSObject

+ (void)setupDatabase:(FMDatabase *)db;
+ (void)autoMigrateDatabase:(FMDatabase *)db;

+ (nullable NSSet<Class> *)modelClassesWithDatabasePath:(NSString *)dbpath;

+ (nullable NSSet<NSString *> *)tablesInDatabase:(FMDatabase *)db;
+ (nullable NSSet<NSString *> *)indexesForTable:(NSString *)table database:(FMDatabase *)db;
+ (nullable NSOrderedSet<NSString *> *)columnsForTable:(NSString *)table database:(FMDatabase *)db;

+ (nullable NSString *)indexNameWithColumns:(NSArray<NSString *> *)columns uniqued:(BOOL)unique;

+ (BOOL)createTableForModel:(Class)modelCls database:(FMDatabase *)db;
+ (BOOL)createIndexForModel:(Class)modelCls
                withColumns:(NSArray<NSString *> *)colnames
                    uniqued:(BOOL)uniqued
                   database:(FMDatabase *)db;

@end

NS_ASSUME_NONNULL_END
