//
//  ALDBMigrationHelper.m
//  alloy
//
//  Created by Alex Lee on 27/07/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDBMigrationHelper.h"
#import "ALOCRuntime.h"
#import "sql_value.hpp"
#import "ALSQLValue.h"
#import "handle.hpp"
#import "ALUtilitiesHeader.h"
#import "ALActiveRecord.h"
#import "NSObject+AL_ActiveRecord.h"
#import "YYClassInfo.h"
#import <BlocksKit.h>
#import <vector>
#import <unordered_map>
extern "C" {
    #import "NSString+ALHelper.h"
    #import "ALLogger.h"
}

static AL_FORCE_INLINE BOOL hasClassMethod(Class cls, NSString *name){
    YYClassInfo *classInfo = [YYClassInfo classInfoWithClass:cls];
    return classInfo.methodInfos[name] != nil;
}

@interface ALDBIndex : NSObject
@property(nonatomic, copy)      NSString  *table;
@property(nonatomic, copy)      NSString  *name;
@property(nonatomic, assign)    BOOL       unique;
@property(nonatomic, copy)      NSArray<NSString *> *columns;

- (BOOL)isEqual:(id)object;
@end

@implementation ALDBIndex

- (NSUInteger)hash {
    if (self.columns.count > 0) {
        return [@(self.unique) hash] ^ [self.columns hash];
    }
    return (NSUInteger)(__bridge void *)self;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if (![object isMemberOfClass:self.class]) {
        return NO;
    }
    
    ALDBIndex *other = (ALDBIndex *)object;
    if ( (self.unique ? 1 : 0) != (other.unique ? 1 : 0)) {
        return NO;
    }
//    
//    if ([self hash] != [object hash]) {i
//        return NO;
//    }
//    
    return [self.columns isEqualToArray:other.columns];
}

@end


@implementation ALDBMigrationHelper

+ (BOOL)setupDatabaseUsingHandle:(const aldb::RecyclableHandle &)handle {
    [[self modelClassesWithDatabasePath:@(handle->get_path().c_str())] bk_each:^(Class cls) {
        [self createTableForModel:cls usingHandle:handle];
    }];
    
    return YES;
}

+ (BOOL)autoMigrateDatabaseUsingHandle:(const aldb::RecyclableHandle &)handle {
    NSMutableSet<NSString *> *tables = [[self getTablesInDatabaseUsingHandle:handle] mutableCopy];
    
    for (Class modelClass in [self modelClassesWithDatabasePath:@(handle->get_path().c_str())]){
        NSString *modelTblName = [modelClass tableName];
        
        //1, table already exists, check and merge
        if ([tables containsObject:modelTblName]) {
            
            // merge table columns
            std::list<const ALDBColumnDefine> tblColumns = [self getTableColumns:modelTblName usingHandle:handle];
            std::list<const std::string> tblColNames;
            for (auto obj : tblColumns) {
                tblColNames.push_back(std::string(obj.column()));
            }
            
            //std::unordered_map<const std::string, std::shared_ptr<aldb::ColumnDefine>>
            for (auto iter : [modelClass al_modelPropertyColumnsMap]) {
                std::string propertyName = iter.first;
                std::shared_ptr<ALDBColumnDefine> modelColumn = iter.second;
                if (modelColumn->column() == ALDBColumn::s_rowid && ![modelClass withoutRowId]) {
                    continue;
                }
                
                // new column
                if (std::find(tblColNames.begin(), tblColNames.end(), propertyName) == tblColNames.end()) {
                    [self addColumn:*modelColumn inTable:[modelClass tableName].UTF8String usingHandle:handle];
                }
            }
            
            // merge indexes
            NSMutableSet<ALDBIndex *> *tblIndexes = [NSMutableSet setWithArray:[self getTableIndexes:modelTblName usingHandle:handle]];
            NSMutableSet<ALDBIndex *> *modelIndexes = [NSMutableSet setWithArray:[self indexesForModel:modelClass]];
            [modelIndexes bk_each:^(ALDBIndex *obj) {
                if ([tblIndexes containsObject:obj]) {
                    [tblIndexes removeObject:obj]; // not changed
                } else {
                    // add index
                    auto clause = [self indexCreationStatementWithIndexInfo:obj];
                    handle->exec(clause.sql_str(), clause.sql_args());
                }
            }];
            // index to be deleted
            [tblIndexes bk_each:^(ALDBIndex *obj) {
                auto clause = [self statementTodropIndex:obj];
                handle->exec(clause.sql_str(), clause.sql_args());
            }];
        } else {
            // new tables
            [self createTableForModel:modelClass usingHandle:handle];
        }
        
        [tables removeObject:modelTblName];
    }

    if (tables.count > 0) {
        ALLogWarn(@"No model associated with these tables, manually drop them if confirmed useless: [%@]",
                  [tables.allObjects componentsJoinedByString:@", "]);
    }
    
    return NO;
}

#pragma mark -
+ (NSSet<Class> *)modelClassesWithDatabasePath:(NSString *)path {
    return [[ALOCRuntime classConfirmsToProtocol:@protocol(ALActiveRecord)] bk_select:^BOOL(Class cls) {
        Class metacls = objc_getMetaClass(object_getClassName(cls));
        
        NSString *pathSelName        = NSStringFromSelector(@selector(databaseIdentifier));
        NSString *autoMigrateSelName = NSStringFromSelector(@selector(autoBindDatabase));
        
        return hasClassMethod(metacls, autoMigrateSelName) && hasClassMethod(metacls, pathSelName) &&
        [[cls databaseIdentifier] isEqualToString:path];
    }];
}

+ (BOOL)createTableForModel:(Class)modelCls usingHandle:(const aldb::RecyclableHandle)handle {
    const ALSQLClause createTableStaement = [self tableSchemaForModel:modelCls];
    bool result = handle->exec(createTableStaement.sql_str(), createTableStaement.sql_args());
    al_guard_or_return1(result, NO, "*** create table for model:%@ failed: %s", modelCls,
                        std::string(*(handle->get_error())).c_str());

    [[modelCls indexKeys] bk_each:^(NSArray<NSString *> *propertieNames) {
        auto clause = [self indexCreationStatementForModel:modelCls indexProperties:propertieNames uniqued:NO];
        if (!handle->exec(createTableStaement.sql_str(), createTableStaement.sql_args())) {
            ALLogError(@"%s", std::string(*(handle->get_error())).c_str());
        }
    }];

    return result;
}

+ (const ALSQLClause)tableSchemaForModel:(Class)modelCls {
    al_guard_or_return1([(id)modelCls respondsToSelector:@selector(tableName)], nil, @"*** model class:%@ does NOT responds to selector: 'tableName'.", modelCls);
    
    const char *tableName = ALCastToTypeOrNil([modelCls tableName], NSString).UTF8String;
    al_guard_or_return1(strlen(tableName) > 0, nil, @"*** Table name for model: %@ is empty!", modelCls);
    
    ALSQLClause clause("CREATE TABLE IF NOT EXISTS " + std::string(tableName) + " (");
    
    //column-def:
    auto columns = [self sortedTableColumnsForModel:modelCls];
    size_t count = columns.size();
    size_t idx = 0;
    for (auto iter : columns) {
        auto coldef = iter.second;
        clause.append(ALSQLClause(*coldef));
        if (idx < count) {
            clause.append(", ");
        }
        idx ++;
    }
    
    // table-constraint:
    // PRIMARY KEY
    NSArray *indexKeys = [[modelCls primaryKeys] bk_map:^NSString *(NSString *propertyName) {
        return [modelCls al_columnNameForPropertyNamed:propertyName];
    }];
    if ([indexKeys count] > 0) {
        clause.append(", PRIMARY KEY (" + std::string([indexKeys componentsJoinedByString:@", "].UTF8String) + ") ");
    }
    // UNIQUE KEY
    indexKeys = [[modelCls uniqueKeys] bk_map:^NSString *(NSString *propertyName) {
        return [modelCls al_columnNameForPropertyNamed:propertyName];
    }];
    if ([indexKeys count] > 0) {
        clause.append(", UNIQUE (" + std::string([indexKeys componentsJoinedByString:@", "].UTF8String) + ") ");
    }
    
    clause.append(")");
    
    if ([modelCls withoutRowId]) {
        clause.append("WITHOUT ROWID");
    }

    return clause;
}

+ (const std::vector<std::pair<const std::string, std::shared_ptr<ALDBColumnDefine>>>)sortedTableColumnsForModel:
    (Class)modelCls {
    std::vector<std::pair<const std::string, std::shared_ptr<ALDBColumnDefine>>> vector;

    std::unordered_map<std::string, std::shared_ptr<ALDBColumnDefine>> map =
        [modelCls al_modelPropertyColumnsMap];
    for (auto iter : map) {
        vector.push_back({iter.first, iter.second});
    }

    // TODO: sort columns
    return vector;
}

//+ (const std::string &)primaryKeyForColumns:(const std::vector<std::pair<const std::string, std::shared_ptr<aldb::ColumnDefine>>> &)columns {
//    for (auto iter : ) {
//        <#statements#>
//    }
//}

+ (const ALSQLClause)indexCreationStatementForModel:(Class)modelCls
                                        indexProperties:(NSArray<NSString *> *)propertyNames
                                                uniqued:(BOOL)unique {
    ALSQLClause clause("CREATE ");
    if (unique) {
        clause.append("UNIQUE ");
    }

    NSArray<NSString *> *colnames = [propertyNames bk_map:^NSString *(NSString *pn) {
        return [modelCls al_columnNameForPropertyNamed:pn];
    }];
    
    clause.append("INDEX IF NOT EXISTS " + [self indexNameForTable:[modelCls tableName] columns:colnames uniqued:unique]);
    clause.append(" ON " + std::string([modelCls tableName].UTF8String) + " (");
    clause.append([colnames componentsJoinedByString:@", "].UTF8String);
    clause.append(")");
    return clause;
}

+ (const ALSQLClause)indexCreationStatementWithIndexInfo:(ALDBIndex *)info {
    ALSQLClause clause("CREATE ");
    if (info.unique) {
        clause.append("UNIQUE ");
    }
    
    clause.append("INDEX IF NOT EXISTS ");
    if (info.name) {
        clause.append(info.name.UTF8String);
    } else {
        clause.append([self indexNameForTable:info.table columns:info.columns uniqued:info.unique]);
    }
    clause.append(" ON " + std::string(info.table.UTF8String) + " (");
    clause.append([info.columns componentsJoinedByString:@", "].UTF8String);
    clause.append(")");
    return clause;
}

+ (const ALSQLClause)statementTodropIndex:(ALDBIndex *)index {
    ALSQLClause clause("DROP INDEX IF EXISTS ");
    clause.append(index.name.UTF8String);
    return clause;
}

+ (const std::string)indexNameForTable:(NSString *)table
                               columns:(NSArray<NSString *> *)columnNames
                               uniqued:(BOOL)unique {
    al_guard_or_return(columnNames.count > 0, "");
    
    std::string s;
    s.append(unique ? "uniq_" : "idx_");
    s.append(std::string(table.UTF8String) + "_");
    s.append(decimalToBaseN([columnNames hash], 36).UTF8String);
    s.append(decimalToBaseN((uint64_t)(CFAbsoluteTimeGetCurrent() * 1000000), 36).UTF8String);
    return s;
}

+ (NSSet<NSString *> *)getTablesInDatabaseUsingHandle:(const aldb::RecyclableHandle)handle {
    NSMutableSet<NSString *> *tables = [NSMutableSet set];
    
    std::shared_ptr<aldb::StatementHandle> stmt = handle->prepare("SELECT tbl_name FROM sqlite_master WHERE type = ? AND name NOT LIKE ?;");
    if (stmt) {
        stmt->bind_value("table", 1);
        stmt->bind_value("sqlite_%", 2);
        while (stmt->step()) {
            [tables addObject: @(stmt->get_text_value(0))];
        }
        stmt->finalize();
    }
    return tables;
}

+ (const std::list<const ALDBColumnDefine>)getTableColumns:(NSString *)table usingHandle:(const aldb::RecyclableHandle)handle {
    
    std::list<const ALDBColumnDefine> colunms;
    std::shared_ptr<aldb::StatementHandle> stmt = handle->prepare("PRAGMA table_info(?);");
    stmt->bind_value(table.UTF8String, 0);
    while (stmt->step()) {
        // sqlite> pragma table_info(test2);
        // cid|name|type|notnull|dflt_value|pk
        ALDBColumnDefine column(ALDBColumn(stmt->get_text_value(1)), stmt->get_text_value(2));
        if (stmt->get_int32_value(3) != 0) {
            column.not_null();
        }
        //TODO: set default value
        
        if (stmt->get_int32_value(5)) {
            column.as_primary();
        }
        
        colunms.push_back(column);
        
    }
    stmt->finalize();
    return colunms;
}

+ (NSArray<ALDBIndex *> *)getTableIndexes:(NSString *)table usingHandle:(const aldb::RecyclableHandle)handle {
    NSMutableArray<ALDBIndex *> *indexes = [NSMutableArray array];
    
    std::shared_ptr<aldb::StatementHandle> listStmt = handle->prepare("PRAGMA index_list(?)");
    std::shared_ptr<aldb::StatementHandle> infoStmt = handle->prepare("PRAGMA index_info(?)");
    listStmt->bind_value(table.UTF8String, 0);
    while(listStmt->step()) {
        //seq|name|unique|origin|partial
        ALDBIndex *info = [[ALDBIndex alloc] init];
        const char *idxName = listStmt->get_text_value(1) ?: "";
        info.name = @(idxName);
        info.unique = listStmt->get_int32_value(2) != 0;
        
        infoStmt->bind_value(idxName, 0);
        NSMutableArray *arr = [NSMutableArray array];
        while (infoStmt->step()) {
            const char *colname = infoStmt->get_text_value(2);
            if (colname) {
                [arr addObject:@(colname)];
            }
        }
        if (arr.count > 0) {
            info.columns = arr;
        }
        [indexes addObject:info];
    }
    infoStmt->finalize();
    listStmt->finalize();
    
    return indexes;
}

+ (NSArray<ALDBIndex *> *)indexesForModel:(Class)modelCls {
    NSMutableArray<ALDBIndex *> *indexes = [NSMutableArray array];
    NSString *table = [modelCls tableName];
    [[modelCls uniqueKeys] bk_each:^(NSArray<NSString *> *pns) {
        ALDBIndex *idx = [[ALDBIndex alloc] init];
        idx.table = table;
        idx.unique = YES;
        idx.columns = [pns bk_map:^NSString *(NSString *pn) {
            return [modelCls al_columnNameForPropertyNamed:pn];
        }];
        [indexes addObject:idx];
    }];
    
    [[modelCls indexKeys] bk_each:^(NSArray<NSString *> *pns) {
        ALDBIndex *idx = [[ALDBIndex alloc] init];
        idx.table = table;
        idx.unique = NO;
        idx.columns = [pns bk_map:^NSString *(NSString *pn) {
            return [modelCls al_columnNameForPropertyNamed:pn];
        }];
        [indexes addObject:idx];
    }];
    return indexes;
}

+ (bool)addColumn:(const ALDBColumnDefine &)coldef inTable:(const std::string &)table usingHandle:(const aldb::RecyclableHandle)handle {
    ALSQLClause clause("ALTER TABLE " + table + " ADD COLUMN ");
    clause.append(coldef);
    return handle->exec(clause.sql_str(), clause.sql_args());
}
@end
