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
#import "handle.hpp"
#import "column_def.hpp"
#import "sql_pragma.hpp"
#import "sql_drop.hpp"
#import "pragma.hpp"
#import "sql_alter_table.hpp"
#import "sql_create_index.hpp"
#import "sql_create_table.hpp"
#import "sql_select.hpp"
#import "column_index.hpp"
#import "ALMacros.h"
#import "YYClassInfo.h"
#import "NSString+ALHelper.h"
#import "ALLogger.h"
#import "ALDatabase.h"
#import "ALActiveRecord.h"
#import "ALDBProperty.h"
#import "ALDBExpr.h"
#import "expr.hpp"
#import "ALDBResultColumn.h"
#import "NSObject+ALDBBindings.h"
#import "NSError+ALDBError.h"
#import "ALDBTableBinding+Database.h"
#import "ALDBIndexBinding.h"
#import "ALDBTypeDefines.h"
#import <unordered_map>
#import <unordered_set>
#import <BlocksKit/BlocksKit.h>
#import <objc/message.h>

static AL_FORCE_INLINE BOOL hasClassMethod(Class cls, NSString *name){
    YYClassInfo *classInfo = [YYClassInfo classInfoWithClass:cls];
    return classInfo.methodInfos[name] != nil;
}

@implementation ALDBMigrationHelper

+ (BOOL)setupDatabaseUsingHandle:(std::shared_ptr<aldb::Handle> &)handle {
    for (Class cls in [self modelClassesWithDatabasePath:@(handle->get_path().c_str())]) {
        ALDBTableBinding *binding = [cls al_tableBindings];
        if (binding == nil) {
            continue;
        }
        auto stmt = [binding statementToCreateTable];
        if (!handle->exec(stmt.sql(), stmt.values())) {
            NSError *error = [NSError errorWithALDBError:*handle->get_error()];
            ALLogError(@"Can not create table for model: %@, Error:%@", cls, error);
            return NO;
        }
        
        [al_safeInvokeSelector(NSArray *, cls, @selector(uniqueKeys)) bk_each:^(NSArray<NSString *> *propertieNames) {
            auto stmt = [binding statementToCreateIndexOnProperties:propertieNames isUnique:YES];
            if (!handle->exec(stmt.sql(), stmt.values())) {
                NSError *error = [NSError errorWithALDBError:*handle->get_error()];
                ALLogWarn(@"Can not create unique index for model: %@, Error:%@", cls, error);
            }
        }];
        
        [al_safeInvokeSelector(NSArray *, cls, @selector(indexKeys)) bk_each:^(NSArray<NSString *> *propertieNames) {
            auto stmt = [binding statementToCreateIndexOnProperties:propertieNames isUnique:NO];
            if (!handle->exec(stmt.sql(), stmt.values())) {
                NSError *error = [NSError errorWithALDBError:*handle->get_error()];
                ALLogWarn(@"Can not create index for model: %@, Error:%@", cls, error);
            }
        }];
    };

    return YES;
}

+ (BOOL)autoMigrateDatabaseUsingHandle:(std::shared_ptr<aldb::Handle> &)handle {
    NSMutableSet<NSString *> *existedTables = [[self getTablesInDatabaseUsingHandle:handle] mutableCopy];

    for (Class modelClass in [self modelClassesWithDatabasePath:@(handle->get_path().c_str())]) {
        NSString *modelTblName = ALTableNameForModel(modelClass);
        ALDBTableBinding *tableBinding = al_safeInvokeSelector(ALDBTableBinding *, modelClass, @selector(al_tableBindings));
        if (!tableBinding) { // model is not bound to database
            continue;
        }

        // 1, table already exists, check and merge
        if ([existedTables containsObject:modelTblName]) {
            // merge table columns
            NSSet<NSString *> *tblColNames = [NSSet setWithArray:[self getTableColumnNames:modelTblName usingHandle:handle]];
            for (ALDBColumnBinding *colBinding in [tableBinding columnBindings]) {
                if (colBinding.columnName.UTF8String == aldb::Column::ROWID.name()) {
                    continue;
                }
                if (![tblColNames containsObject:colBinding.columnName]) {
                    // new column
                    auto coldef = colBinding.columnDefine;
                    if (coldef) {
                        if(!handle->exec(coldef->sql(), coldef->values())) {
                            ALLogError(@"%@", [NSError errorWithALDBError:*handle->get_error()]);
                        }
                    }
                }
            }

            // merge indexes
            // TODO: need to find out a way to check if an existed inddex is equal to the one defined in model.
            // The problem is:
            //      1, how to get the define of the existed index on expression(eg: create index idx_1001 on table test_1 (k3 > 'abc' and k3 < '567', k4);)?
            //      2, how to merge the "sqlite_autoindex_xxx"(defined via table constraints or unique constraints) index?
            // Jusy simplely add new conlumns until find out the way.
            [al_safeInvokeSelector(NSArray *, modelClass, @selector(uniqueKeys)) bk_each:^(NSArray<NSString *> *properties) {
                auto stmt = [tableBinding statementToCreateIndexOnProperties:properties isUnique:YES];
                if(!handle->exec(stmt.sql(), stmt.values())) {
                    ALLogError(@"%@", [NSError errorWithALDBError:*handle->get_error()]);
                }
            }];
            [al_safeInvokeSelector(NSArray *, modelClass, @selector(indexKeys)) bk_each:^(NSArray<NSString *> *properties) {
                auto stmt = [tableBinding statementToCreateIndexOnProperties:properties isUnique:NO];
                if(!handle->exec(stmt.sql(), stmt.values())) {
                    ALLogError(@"%@", [NSError errorWithALDBError:*handle->get_error()]);
                }
            }];

        } else {
            // new tables
            auto stmt = [tableBinding statementToCreateTable];
            if(!handle->exec(stmt.sql(), stmt.values())) {
                ALLogError(@"%@", [NSError errorWithALDBError:*handle->get_error()]);
            }
        }
        [existedTables removeObject:modelTblName];
    }

    if (existedTables.count > 0) {
        ALLogWarn(@"No model associated with these tables, manually drop them if confirmed useless: [%@]",
                  [existedTables.allObjects componentsJoinedByString:@", "]);
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
               [cls autoBindDatabase] && [[cls databaseIdentifier] isEqualToString:path];
    }];
}

+ (NSSet<NSString *> *)getTablesInDatabaseUsingHandle:(std::shared_ptr<aldb::Handle> &)handle {
    NSMutableSet<NSString *> *tables = [NSMutableSet set];
    aldb::SQLSelect select =
        aldb::SQLSelect()
            .select(ALDBResultColumnList(ALDBProperty("tbl_name")), true)
            .from("sqlite_master")
            .where(ALDBProperty("type") == "table" && ALDBProperty("name").not_like("sqlite\\_%", "\\"));
    auto stmt = handle->prepare(select.sql());
    if (stmt) {
        int index = 0;
        for (auto val : select.values()) {
            stmt->bind_value(val, index++);
        }
        while (stmt->next_row()) {
            [tables addObject: @(stmt->get_text_value(0))];
        }
    }
    return tables;
}

+ (NSArray<NSString *> *)getTableColumnNames:(NSString *)table usingHandle:(std::shared_ptr<aldb::Handle> &)handle {
    auto stmt = handle->prepare(aldb::SQLPragma().pragma(aldb::Pragma::TABLE_INFO, table.UTF8String).sql());
    if (!stmt) {
        ALLogError(@"%s", handle->get_error()->description().c_str());
        return nil;
    }

    NSMutableArray *columns = [NSMutableArray array];
    while (stmt->next_row()) {
        // cid|name|type|notnull|dflt_value|pk
        [columns addObject:@(stmt->get_text_value(1))];
    }
    stmt->finalize();
    return columns;
}

+ (std::list<const aldb::ColumnDef>)getTableColumns:(NSString *)table
                                        usingHandle:(std::shared_ptr<aldb::Handle> &)handle {
    std::list<const aldb::ColumnDef> columns;
    auto stmt = handle->prepare(aldb::SQLPragma().pragma(aldb::Pragma::TABLE_INFO, table.UTF8String).sql());
    if (!stmt) {
        ALLogError(@"%s", handle->get_error()->description().c_str());
        return columns;
    }

    while (stmt->next_row()) {
        // cid|name|type|notnull|dflt_value|pk
        aldb::ColumnDef column(stmt->get_text_value(1), aldb::column_type_for_name(stmt->get_text_value(2)));
        
        if (stmt->get_int32_value(3) != 0) {
            column.not_null();
        }

        // set default value
        std::string dftVal = stmt->get_text_value(4);
        if ((dftVal.front() == '"' && dftVal.back() == '"') || (dftVal.front() == '\'' && dftVal.back() == '\'')) {
            dftVal = dftVal.substr(1, dftVal.size() - 2);
            column.default_value(aldb::SQLValue(dftVal));
        } else {
            aldb::DefaultTimeValue timeVal = aldb::default_time_value_from_string(dftVal);
            if (timeVal != aldb::DefaultTimeValue::NOT_SET) {
                column.default_value(timeVal);
            } else if (aldb::str_to_upper(dftVal) == "NULL") {
                column.default_value(nullptr);
            } else {
                column.default_value(aldb::SQLValue(dftVal));
            }
        }
        // primary key?
        if (stmt->get_int32_value(5) != 0) {
            column.as_primary();
        }
        columns.push_back(column);
    }
    stmt->finalize();
    return columns;
}

+ (NSArray<NSString *> *)getIndexNamesInTable:(NSString *)table usingHandle:(std::shared_ptr<aldb::Handle> &)handle {
    NSMutableArray<NSString *> *indexes = [NSMutableArray array];
    auto stmt = handle->prepare(aldb::SQLPragma().pragma(aldb::Pragma::INDEX_LIST, table.UTF8String).sql());
    if (stmt) {
        // seq|name|unique|origin|partial
        while (stmt->next_row()) {
            [indexes addObject:@(stmt->get_text_value(1) ?: "")];
        }
        stmt->finalize();
    }
    return indexes;
}

+ (NSArray<ALDBIndexBinding *> *)getIndexesInTable:(NSString *)table usingHandle:(std::shared_ptr<aldb::Handle> &)handle {
    NSMutableArray<ALDBIndexBinding *> *indexes = [NSMutableArray array];
    auto stmt = handle->prepare(aldb::SQLPragma().pragma(aldb::Pragma::INDEX_LIST, table.UTF8String).sql());
    if (stmt) {
        // seq|name|unique|origin|partial
        while (stmt->next_row()) {
            ALDBIndexBinding *index =
                [ALDBIndexBinding indexBindingWithTableName:table isUnique:stmt->get_int32_value(2) != 0];
            index.indexName = @(stmt->get_text_value(1) ?: "");

            auto xinfoStmt =
                handle->prepare(aldb::SQLPragma().pragma(aldb::Pragma::INDEX_XINFO, stmt->get_text_value(1)).sql());
            if (xinfoStmt) {
                while (xinfoStmt->next_row()) {
                    // seqno|cid|name|desc|coll|key
                    if (xinfoStmt->get_int32_value(5) != 0) {  // key
                        [index addIndexColumn:ALDBIndex(aldb::Column(xinfoStmt->get_text_value(2)),
                                                        xinfoStmt->get_text_value(4),
                                                        xinfoStmt->get_int32_value(3) != 0 ? aldb::OrderBy::DESC
                                                                                           : aldb::OrderBy::DEFAULT)];
                    }
                }
                xinfoStmt->finalize();
            }

            [indexes addObject:index];
        }
        stmt->finalize();
    }
    return indexes;
}

@end
