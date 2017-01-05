//
//  ALDBMigrationHelper.m
//  patchwork
//
//  Created by Alex Lee on 04/01/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDBMigrationHelper.h"
#import "ALOCRuntime.h"
#import "NSString+Helper.h"
#import <BlocksKit.h>
#import "PatchworkLog_private.h"


static AL_FORCE_INLINE BOOL hasClassMethod(Class cls, NSString *name){
    BOOL found = NO;
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(cls, &methodCount);
    if (methods) {
        for (unsigned int i = 0; i < methodCount; i++) {
            SEL sel = method_getName(methods[i]);
            NSString *methodName = [NSString stringWithUTF8String:sel_getName(sel)];
            if ([methodName isEqualToString:name]) {
                found =  YES;
                break;
            }
        }
        free(methods);
    }
    return found;
}

static AL_FORCE_INLINE BOOL executeSQL(NSString *sql, FMDatabase *db) {
    if ([db executeUpdate:sql]) {
        return YES;
    }
    ALLogError(@"Execute SQL: %@; ⛔ ERROR: %@", sql, [db lastError]);
    return NO;
}


@implementation ALDBMigrationHelper

+ (NSSet<Class> *)modelClassesWithDatabasePath:(NSString *)dbpath {
    return [[ALOCRuntime subClassesOf:[ALModel class]] bk_select:^BOOL(Class cls) {
        Class metacls = objc_getMetaClass(object_getClassName(cls));
        NSString *name = NSStringFromSelector(@selector(databaseIdentifier));
        return hasClassMethod(metacls, name) && [[cls databaseIdentifier] isEqualToString:dbpath];
    }];
}

+ (NSSet<NSString *> *)tablesInDatabase:(FMDatabase *)db {
    FMResultSet *rs =
        [db executeQuery:@"SELECT tbl_name FROM sqlite_master WHERE type = ? AND name NOT LIKE ?", @"table", @"sqlite_%"];
    if (rs == nil) {
        return nil;
    }

    NSMutableSet *tables = [NSMutableSet set];
    while ([rs next]) {
        [tables addObject:[rs stringForColumnIndex:0]];
    }
    [rs close];

    return tables;
}

+ (NSSet<NSString *> *)indexesForTable:(NSString *)table database:(FMDatabase *)db {
    if (isEmptyString(table)) {
        NSAssert(NO, @"*** parameter 'table' is empty!");
        return nil;
    }
    
    FMResultSet *rs =
    [db executeQuery:@"SELECT name FROM sqlite_master WHERE type = ? AND tbl_name = ?", @"index", table];
    if (rs == nil) {
        return nil;
    }
    
    NSMutableSet *indexes = [NSMutableSet set];
    while ([rs next]) {
        [indexes addObject:[rs stringForColumnIndex:0]];
    }
    [rs close];
    
    return indexes;
}

+ (NSOrderedSet<NSString *> *)columnsForTable:(NSString *)table database:(FMDatabase *)db {
    if (isEmptyString(table)) {
        NSAssert(NO, @"*** parameter 'table' is empty!");
        return nil;
    }
    FMResultSet *rs = [db executeQuery:[NSString stringWithFormat:@"PRAGMA table_info('%@')", table]];
    if (rs == nil || rs.columnCount < 2) {
        return nil;
    }
    
    NSMutableOrderedSet *columns = [NSMutableOrderedSet orderedSet];
    while ([rs next]) {
        [columns addObject:[rs stringForColumnIndex:1]];
    }
    [rs close];
    
    return columns;
}

+ (BOOL)createTableForModel:(Class)modelCls database:(FMDatabase *)db {
    BOOL result = executeSQL([self tableSchemaForModel:modelCls], db);
    if (result) {
        [self migrateIndexes:[modelCls uniqueKeys] uniqued:YES forModel:modelCls withExistedKeys:nil database:db];
        [self migrateIndexes:[modelCls indexKeys] uniqued:NO forModel:modelCls withExistedKeys:nil database:db];
    }
    return result;
}

+ (nullable NSString *)indexNameWithColumns:(NSArray<NSString *> *)columns uniqued:(BOOL)unique {
    if (columns.count == 0) {
        NSAssert(NO, @"index columns is empty!");
        return nil;
    }

    return [(unique ? @"uniq_" : @"idx_") stringByAppendingString:[columns componentsJoinedByString:@"#"]];
}

+ (BOOL)createIndexForModel:(Class)modelCls
                withColumns:(NSArray<NSString *> *)colnames
                    uniqued:(BOOL)uniqued
                   database:(FMDatabase *)db {
    
    NSString *sql = [NSString stringWithFormat:@"CREATE %@INDEX IF NOT EXISTS %@ ON %@(%@)",
                     (uniqued ? @"UNIQUE " : @""),
                     [self indexNameWithColumns:colnames uniqued:uniqued],
                     [modelCls tableName],
                     [colnames componentsJoinedByString:@", "]];
    return executeSQL(sql, db);
}

+ (nullable NSString *)tableSchemaForModel:(Class)modelCls {
    NSString *tableName = castToTypeOrNil([modelCls tableName], NSString);
    if (tableName.length == 0) {
        NSAssert(NO, @"*** Table name for model: %@ is empty!", modelCls);
        return nil;
    }
    
    NSMutableString *sqlClause = [NSMutableString string];
    
    // CREATE TABLE
    [sqlClause appendFormat:@"CREATE TABLE IF NOT EXISTS %@ (", tableName];
    
    // COLUMN DEF
    [sqlClause appendString:[[[[[modelCls columns] bk_reject:^BOOL(NSString *key, id obj) {
        return [key isEqualToString:keypathForClass(ALModel, rowid)];
    }].allValues sortedArrayUsingComparator:[modelCls columnOrderComparator]]
                              bk_map:^NSString *(ALDBColumnInfo *column) {
                                  return [column columnDefine];
                              }] componentsJoinedByString:@", "]];
    
    // PRIMARY KEY
    NSArray *indexKeys = [[modelCls primaryKeys] bk_map:^NSString *(NSString *propertyName) {
        return [modelCls mappedColumnNameForProperty:propertyName];
    }];
    if ([indexKeys count] > 0) {
        [sqlClause appendFormat:@", PRIMARY KEY (%@)", [indexKeys componentsJoinedByString:@", "]];
    }
    
    [sqlClause appendString:@")"];
    
    if ([modelCls withoutRowId]) {
        [sqlClause appendString:@"WITHOUT ROWID"];
    }
    
    return [sqlClause copy];
}

// private
+ (void)migrateIndexes:(NSArray<NSArray<NSString *> *> *)keys
               uniqued:(BOOL)uniqued
              forModel:(Class)modelCls
       withExistedKeys:(NSMutableSet *)tblIdxes
              database:(FMDatabase *)db {
    
    [keys bk_each:^(NSArray<NSString *> *arr) {
        arr = [arr bk_map:^NSString *(NSString *propName) {
            return [modelCls mappedColumnNameForProperty:propName];
        }];
        
        NSString *idxname = [self indexNameWithColumns:arr uniqued:uniqued];
        if (![tblIdxes containsObject:idxname]) { // new index
            [self createIndexForModel:modelCls withColumns:arr uniqued:uniqued database:db];
        }
        [tblIdxes removeObject:idxname];
    }];
}

+ (void)autoMigrateDatabase:(FMDatabase *)db {
    NSMutableSet *tables = [[self tablesInDatabase:db] mutableCopy];
    
    for (Class modelClass in [self modelClassesWithDatabasePath:db.databasePath]){
        NSString *modelTblName = [modelClass tableName];
        if ([tables containsObject:modelTblName]) {
            
            // migrate columns
            NSOrderedSet *tblColumns = [self columnsForTable:modelTblName database:db];
            [[modelClass columns] bk_each:^(id key, ALDBColumnInfo *colinfo) {
                if (![tblColumns containsObject:colinfo.name]) {// new column
                    executeSQL([NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@", modelTblName,
                                [colinfo columnDefine]], db);
                }
            }];
            
            // migrate indexes
            NSMutableSet *tblIdxes = [[self indexesForTable:modelTblName database:db] mutableCopy];
            [self migrateIndexes:[modelClass uniqueKeys]
                         uniqued:YES
                        forModel:modelClass
                 withExistedKeys:tblIdxes
                        database:db];
            [self migrateIndexes:[modelClass indexKeys]
                         uniqued:NO
                        forModel:modelClass
                 withExistedKeys:tblIdxes
                        database:db];
            
            for (NSString *idxName in tblIdxes) {
                executeSQL([NSString stringWithFormat:@"DROP INDEX IF EXISTS %@", idxName], db);
            }

        } else {
            [self createTableForModel:modelClass database:db];
        }
        
        [tables removeObject:modelTblName];
    }
    
    if (tables.count > 0) {
        _ALDBLog(@"No model associated with these tables, manually drop them if confirmed useless: [%@]",
                 [tables.allObjects componentsJoinedByString:@", "]);
    }
}


@end
