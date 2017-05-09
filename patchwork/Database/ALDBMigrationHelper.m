//
//  ALDBMigrationHelper.m
//  patchwork
//
//  Created by Alex Lee on 04/01/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDBMigrationHelper.h"
#import "ALOCRuntime.h"
#import "NSString+ALHelper.h"
#import <BlocksKit.h>
#import "__patchwork_config.h"


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


@implementation ALDBMigrationHelper

+ (BOOL)executeSQL:(NSString *)sql database:(FMDatabase *)db {
    if ([db executeUpdate:sql]) {
        return YES;
    }
    ALLogError(@"Execute SQL: %@; ⛔ ERROR: %@", sql, [db lastError]);
    return NO;
}

+ (void)setupDatabase:(FMDatabase *)db {
    [[self modelClassesWithDatabasePath:db.databasePath] bk_each:^(Class cls) {
        if ([self createTableForModel:cls database:db]) {
            ALLogInfo(@"Table '%@' created!", [cls tableName]);
        }
    }];
}

+ (void)autoMigrateDatabase:(FMDatabase *)db {
    NSMutableSet *tables = [[self tablesInDatabase:db] mutableCopy];
    
    for (Class modelClass in [self modelClassesWithDatabasePath:db.databasePath]){
        NSString *modelTblName = [modelClass tableName];
        if ([tables containsObject:modelTblName]) {
            
            // migrate columns
            NSOrderedSet *tblColumns = [self columnsForTable:modelTblName database:db];
            [[modelClass tableColumns] bk_each:^(id key, ALDBColumnInfo *colinfo) {
                if ([colinfo.name isEqualToString:kRowIdColumnName] && ![modelClass withoutRowId]) {
                    return;
                }
                if (![tblColumns containsObject:colinfo.name]) {// new column
                    ALLogInfo(@"Table: '%@', ADD new column: '%@'", modelTblName, colinfo.name);
                    [self executeSQL:[NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@", modelTblName,
                                                                [colinfo columnDefine]]
                            database:db];
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
                ALLogInfo(@"Table: '%@', DROP index: '%@'", modelTblName, idxName);
                [self executeSQL: [NSString stringWithFormat:@"DROP INDEX IF EXISTS %@", idxName] database:db];
            }
            
        } else {
            if ([self createTableForModel:modelClass database:db]) {
                ALLogInfo(@"Table '%@' created!", modelTblName);
            }
        }
        
        [tables removeObject:modelTblName];
    }
    
    if (tables.count > 0) {
        ALLogWarn(@"No model associated with these tables, manually drop them if confirmed useless: [%@]",
                 [tables.allObjects componentsJoinedByString:@", "]);
    }
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
        
        NSString *tblname = [modelCls tableName];
        NSString *idxname = [self indexNameForTable:tblname columns:arr uniqued:uniqued];
        if (![tblIdxes containsObject:idxname]) { // new index
            if ([self createIndexForModel:modelCls withColumns:arr uniqued:uniqued database:db]) {
                ALLogInfo(@"Table: '%@', ADD new index: '%@'", tblname, idxname);
            }
        }
        [tblIdxes removeObject:idxname];
    }];
}

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
        ALLogError(@"%@", [db lastError]);
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
    al_guard_or_return(!al_isEmptyString(table), nil);
    
    FMResultSet *rs =
    [db executeQuery:@"SELECT name FROM sqlite_master WHERE type = ? AND tbl_name = ?", @"index", table];
    if (rs == nil) {
        ALLogError(@"%@", [db lastError]);
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
    al_guard_or_return(!al_isEmptyString(table), nil);
    
    NSString *sql = [NSString stringWithFormat:@"PRAGMA table_info('%@')", table];
    FMResultSet *rs = [db executeQuery:sql];
    
    al_guard_or_return1(rs != nil && rs.columnCount >= 2, nil,
                        @"*** Can not get table columns info, SQL: %@, ERROR: %@", sql, [db lastError]);

    NSMutableOrderedSet *columns = [NSMutableOrderedSet orderedSet];
    while ([rs next]) {
        [columns addObject:[rs stringForColumnIndex:1]];
    }
    [rs close];
    
    return columns;
}

+ (BOOL)createTableForModel:(Class)modelCls database:(FMDatabase *)db {
    BOOL result = [self executeSQL:[self tableSchemaForModel:modelCls] database:db];
    if (result) {
        [[modelCls uniqueKeys] bk_each:^(NSArray<NSString *> * keys) {
            [self createIndexForModel:modelCls withColumns:[keys bk_map:^NSString *(NSString *propname) {
                return [modelCls mappedColumnNameForProperty:propname];
            }] uniqued:YES database:db];
        }];
        
        [[modelCls indexKeys] bk_each:^(NSArray<NSString *> * keys) {
            [self createIndexForModel:modelCls withColumns:[keys bk_map:^NSString *(NSString *propname) {
                return [modelCls mappedColumnNameForProperty:propname];
            }] uniqued:NO database:db];
        }];
    }
    return result;
}

+ (nullable NSString *)indexNameForTable:(NSString *)table columns:(NSArray<NSString *> *)columns uniqued:(BOOL)unique {
    al_guard_or_return(columns.count > 0, nil);

    return [NSString stringWithFormat:@"%@_%@_$_%@", (unique ? @"uniq" : @"idx"), table,
                                      [columns componentsJoinedByString:@"_$_"]];
}

+ (BOOL)createIndexForModel:(Class)modelCls
                withColumns:(NSArray<NSString *> *)colnames
                    uniqued:(BOOL)uniqued
                   database:(FMDatabase *)db {
    
    NSString *tblname = [modelCls tableName];
    NSString *sql = [NSString stringWithFormat:@"CREATE %@INDEX IF NOT EXISTS %@ ON %@(%@)",
                     (uniqued ? @"UNIQUE " : @""),
                     [self indexNameForTable:tblname columns:colnames uniqued:uniqued],
                     tblname,
                     [colnames componentsJoinedByString:@", "]];
    return [self executeSQL:sql database:db];
}

+ (nullable NSString *)tableSchemaForModel:(Class)modelCls {
    NSString *tableName =ALCastToTypeOrNil([modelCls tableName], NSString);
    al_guard_or_return1(!al_isEmptyString(tableName), nil, @"*** Table name for model: %@ is empty!", modelCls);
    
    NSMutableString *sqlClause = [NSMutableString string];
    
    // CREATE TABLE
    [sqlClause appendFormat:@"CREATE TABLE IF NOT EXISTS %@ (", tableName];
    
    // COLUMN DEF
    [sqlClause appendString:[[[[[modelCls tableColumns] bk_reject:^BOOL(NSString *key, id obj) {
        return [key isEqualToString:al_keypathForClass(ALModel, rowid)] && ![modelCls withoutRowId];
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

@end
