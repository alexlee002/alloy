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
#import <unordered_map>
#import <unordered_set>
#import "NSString+ALHelper.h"
#import "ALLogger.h"
#import "ALSQLCreateTable.h"
#import "ALSQLCreateIndex.h"
#import <objc/message.h>
#import "__ALModelMeta+ActiveRecord.h"

static AL_FORCE_INLINE BOOL hasClassMethod(Class cls, NSString *name){
    YYClassInfo *classInfo = [YYClassInfo classInfoWithClass:cls];
    return classInfo.methodInfos[name] != nil;
}

@interface __ALDBIndex : NSObject
@property(nonatomic, copy)      NSString  *table;
@property(nonatomic, copy)      NSString  *name;
@property(nonatomic, assign)    BOOL       unique;
@property(nonatomic, copy)      NSArray<NSString *> *columns;

- (BOOL)isEqual:(id)object;
@end

@implementation __ALDBIndex

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
    
    __ALDBIndex *other = (__ALDBIndex *)object;
    if ( (self.unique ? 1 : 0) != (other.unique ? 1 : 0)) {
        return NO;
    }
    
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

    for (Class modelClass in [self modelClassesWithDatabasePath:@(handle->get_path().c_str())]) {
        NSString *modelTblName = al_safeInvokeSelector(NSString *, modelClass, @selector(tableName));

        // 1, table already exists, check and merge
        if ([tables containsObject:modelTblName]) {
            // merge table columns
            std::list<const ALDBColumnDefine> tblColumns = [self getTableColumns:modelTblName usingHandle:handle];
            std::unordered_set<std::string> tblColNames;
            for (auto obj : tblColumns) {
                tblColNames.insert(std::string(obj.column()));
            }

            // check table columns
            _ALModelTableBindings *modelBindings = [_ALModelTableBindings bindingsWithClass:modelClass];
            for (ALPropertyColumnBindings *colBinding in modelBindings->_allColumns) {
                ALDBColumn col = [colBinding columnDefine].column();
                if (!al_safeInvokeSelector(BOOL, modelClass, @selector(withoutRowId)) && col == ALDBColumn::s_rowid) {
                    continue;
                }

                // new column
                if (std::find(tblColNames.begin(), tblColNames.end(), std::string(col)) == tblColNames.end()) {
                    [self addColumn:[colBinding columnDefine]
                            inTable:modelTblName.UTF8String
                        usingHandle:handle];
                }
            }

            // merge indexes
            NSMutableSet<__ALDBIndex *> *tblIndexes =
                [NSMutableSet setWithArray:[self getTableIndexes:modelTblName usingHandle:handle]];
            NSMutableSet<__ALDBIndex *> *modelIndexes = [NSMutableSet setWithArray:[self indexesForModel:modelClass]];
            [modelIndexes bk_each:^(__ALDBIndex *obj) {
                if ([tblIndexes containsObject:obj]) {
                    [tblIndexes removeObject:obj];  // not changed
                } else {
                    // add index
                    auto clause =
                        [[self indexStatementWithTable:obj.table columns:obj.columns unique:obj.unique] SQLClause];
                    handle->exec(clause.sql_str(), clause.sql_args());
                }
            }];
            // index to be deleted
            [tblIndexes bk_each:^(__ALDBIndex *obj) {
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

    [al_safeInvokeSelector(NSArray *, modelCls, @selector(uniqueKeys)) bk_each:^(NSArray<NSString *> *propertieNames) {
        ALSQLStatement *stmt = [self indexStatementForModel:modelCls indexProperties:propertieNames uniqued:YES];
        ALSQLClause clause   = [stmt SQLClause];
        if (!handle->exec(clause.sql_str(), clause.sql_args())) {
            ALLogError(@"%s", handle->get_error()->description());
        }
    }];

    [al_safeInvokeSelector(NSArray *, modelCls, @selector(indexKeys)) bk_each:^(NSArray<NSString *> *propertieNames) {
        ALSQLStatement *stmt = [self indexStatementForModel:modelCls indexProperties:propertieNames uniqued:NO];
        ALSQLClause clause   = [stmt SQLClause];
        if (!handle->exec(clause.sql_str(), clause.sql_args())) {
            ALLogError(@"%s", handle->get_error()->description());
        }
    }];

    return result;
}

+ (const ALSQLClause)tableSchemaForModel:(Class)modelCls {
    al_guard_or_return1([(id)modelCls respondsToSelector:@selector(tableName)], nil, @"*** model class:%@ does NOT responds to selector: 'tableName'.", modelCls);
    
    NSString *tableName = al_safeInvokeSelector(NSString *, modelCls, @selector(tableName));
    al_guard_or_return1(!al_isEmptyString(tableName), nil, @"*** Table name for model: %@ is empty!", modelCls);
    
    _ALModelTableBindings *tableBindings = [_ALModelTableBindings bindingsWithClass:modelCls];
    ALSQLCreateTable *stmt = [[ALSQLCreateTable statement] createTable:tableName];
    
    //columns
    {
        std::list<const ALDBColumnDefine> columnDefs;
        for (ALPropertyColumnBindings *conlumBinding in tableBindings->_allColumns) {
            columnDefs.push_back(conlumBinding.columnDefine);
        }
        if (columnDefs.size() > 0) {
            [stmt columnDefines:columnDefs];
        }
    }
    
    // primary keys
    {
        std::list<const ALDBIndexedColumn> primaryKeys;
        for (NSString *pk in al_safeInvokeSelector(NSArray *, modelCls, @selector(primaryKeys))) {
            NSString *colname = [tableBindings columnNameForProperty:pk];
            primaryKeys.push_back(ALDBIndexedColumn(ALDBColumn(colname.UTF8String)));
        }
        if (primaryKeys.size() > 0) {
            [stmt constraints:{ALDBTableConstraint().primary_key(primaryKeys)}];
        }
    }
    
    [stmt withoutRowId:al_safeInvokeSelector(BOOL, modelCls, @selector(withoutRowId))];
    
    return [stmt SQLClause];

    
//    
//    // uniques
//    {
//        for (NSArray<NSString *> *ps in [modelCls uniqueKeys]) {
//            std::list<const ALDBIndexedColumn> uniques;
//            for (NSString * p in ps) {
//                NSString *colname = [tableBindings columnNameForProperty:p];
//                uniques.push_back(ALDBIndexedColumn(ALDBColumn(colname.UTF8String)));
//            }
//            constraints.push_back(ALDBTableConstraint().unique(uniques));
//        }
//    }
//    
//    // indexes
//    {
//        for (NSArray<NSString *> *ps in [modelCls uniqueKeys]) {
//            std::list<const ALDBIndexedColumn> indexes;
//            for (NSString * p in ps) {
//                NSString *colname = [tableBindings columnNameForProperty:p];
//                indexes.push_back(ALDBIndexedColumn(ALDBColumn(colname.UTF8String)));
//            }
//            constraints.push_back(ALDBTableConstraint().(indexes));
//        }
//    }
    
//
//    
//    
//    ALSQLClause clause("CREATE TABLE IF NOT EXISTS " + std::string(tableName) + " (");

    //TODO:
//    column-def:
//    auto columns = [self sortedTableColumnsForModel:modelCls];
//    size_t count = columns.size();
//    size_t idx = 0;
//    for (auto iter : columns) {
//        auto coldef = iter.second;
//        clause.append(ALSQLClause(*coldef));
//        if (idx < count) {
//            clause.append(", ");
//        }
//        idx ++;
//    }
//    
//    // table-constraint:
//    // PRIMARY KEY
//    NSArray *indexKeys = [[modelCls primaryKeys] bk_map:^NSString *(NSString *propertyName) {
//        return [modelCls al_columnNameForPropertyNamed:propertyName];
//    }];
//    if ([indexKeys count] > 0) {
//        clause.append(", PRIMARY KEY (" + std::string([indexKeys componentsJoinedByString:@", "].UTF8String) + ") ");
//    }
//    // UNIQUE KEY
//    indexKeys = [[modelCls uniqueKeys] bk_map:^NSString *(NSString *propertyName) {
//        return [modelCls al_columnNameForPropertyNamed:propertyName];
//    }];
//    if ([indexKeys count] > 0) {
//        clause.append(", UNIQUE (" + std::string([indexKeys componentsJoinedByString:@", "].UTF8String) + ") ");
//    }
//    
//    clause.append(")");
//    
//    if ([modelCls withoutRowId]) {
//        clause.append("WITHOUT ROWID");
//    }

//    return clause;
}


//+ (const std::vector<std::pair<const std::string, std::shared_ptr<ALDBColumnDefine>>>)sortedTableColumnsForModel:
//    (Class)modelCls {
//    std::vector<std::pair<const std::string, std::shared_ptr<ALDBColumnDefine>>> vector;
//
//    std::unordered_map<std::string, std::shared_ptr<ALDBColumnDefine>> map =
//        [modelCls al_modelPropertyColumnsMap];
//    for (auto iter : map) {
//        vector.push_back({iter.first, iter.second});
//    }
//
//    // TODO: sort columns
//    return vector;
//}

//+ (const std::string &)primaryKeyForColumns:(const std::vector<std::pair<const std::string, std::shared_ptr<aldb::ColumnDefine>>> &)columns {
//    for (auto iter : ) {
//        <#statements#>
//    }
//}

+ (ALSQLCreateIndex *)indexStatementForModel:(Class)modelCls
                             indexProperties:(NSArray<NSString *> *)propertyNames
                                     uniqued:(BOOL)unique {
    
    return [self indexStatementWithTable:al_safeInvokeSelector(NSString *, modelCls, @selector(tableName))
                                 columns:[propertyNames bk_map:^NSString *(NSString *pn) {
                                     return [modelCls al_columnNameForPropertyNamed:pn];
                                 }]
                                  unique:unique];
}

+ (ALSQLCreateIndex *)indexStatementWithTable:(NSString *)table
                                      columns:(NSArray<NSString *> *)columnNames
                                       unique:(BOOL)unique {
    std::list<const ALDBIndexedColumn> columns;
    for (NSString *cn in columnNames) {
        columns.push_back(ALDBIndexedColumn(ALDBColumn(cn)));
    }

    NSString *indexName = [self indexNameForTable:table columns:columnNames uniqued:unique];
    return [[[[ALSQLCreateIndex alloc] init] createIndex:indexName unique:unique ifNotExists:YES] onTable:table
                                                                                                  columns:columns];
}

+ (const ALSQLClause)statementTodropIndex:(__ALDBIndex *)index {
    ALSQLClause clause("DROP INDEX IF EXISTS ");
    clause.append(index.name.UTF8String);
    return clause;
}

+ (nullable NSString *)indexNameForTable:(NSString *)table
                               columns:(NSArray<NSString *> *)columnNames
                               uniqued:(BOOL)unique {
    al_guard_or_return(columnNames.count > 0, nil);
    
    NSMutableString *s = [(unique ? @"uniq_" : @"idx_") mutableCopy];
    [s appendString:table];
    [s appendString:@"_"];
    [s appendString:decimalToBaseN([columnNames hash], 36)];
    [s appendString:decimalToBaseN((uint64_t)(CFAbsoluteTimeGetCurrent() * 1000000), 36)];
    return [s copy];
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
    std::shared_ptr<aldb::StatementHandle> stmt =
        handle->prepare("PRAGMA table_info(" + std::string(table.UTF8String) + ");");
    if (!stmt) {
        if (handle->has_error()) {
            ALLogError(@"%s", handle->get_error()->description());
        }
        return {};
    }
    
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

+ (NSArray<__ALDBIndex *> *)getTableIndexes:(NSString *)table usingHandle:(const aldb::RecyclableHandle)handle {
    NSMutableArray<__ALDBIndex *> *indexes = [NSMutableArray array];
    
    std::string table_name = std::string(table.UTF8String);
    std::shared_ptr<aldb::StatementHandle> listStmt = handle->prepare("PRAGMA index_list(" + table_name + ")");
    while(listStmt->step()) {
        //seq|name|unique|origin|partial
        __ALDBIndex *info = [[__ALDBIndex alloc] init];
        const char *idxName = listStmt->get_text_value(1) ?: "";
        info.name = @(idxName);
        info.unique = listStmt->get_int32_value(2) != 0;

        std::shared_ptr<aldb::StatementHandle> infoStmt =
            handle->prepare("PRAGMA index_info(" + std::string(idxName) + ")");
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
    return indexes;
}

+ (NSArray<__ALDBIndex *> *)indexesForModel:(Class)modelCls {
    NSMutableArray<__ALDBIndex *> *indexes = [NSMutableArray array];
    NSString *table = al_safeInvokeSelector(NSString *, modelCls, @selector(tableName));
    [al_safeInvokeSelector(NSArray *, modelCls, @selector(uniqueKeys)) bk_each:^(NSArray<NSString *> *pns) {
        __ALDBIndex *idx = [[__ALDBIndex alloc] init];
        idx.table = table;
        idx.unique = YES;
        idx.columns = [pns bk_map:^NSString *(NSString *pn) {
            return [modelCls al_columnNameForPropertyNamed:pn];
        }];
        [indexes addObject:idx];
    }];
    
    [al_safeInvokeSelector(NSArray *, modelCls, @selector(indexKeys)) bk_each:^(NSArray<NSString *> *pns) {
        __ALDBIndex *idx = [[__ALDBIndex alloc] init];
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
