//
//  ALDBTableBinding+Database.m
//  alloy
//
//  Created by Alex Lee on 16/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDBTableBinding+Database.h"
#import "ALDBTableBinding_Private.h"
#import "_ALModelMeta.h"
#import "NSObject+AL_Database.h"
#import "table_constraint.hpp"
#import "ALLogger.h"
#import "ALMacros.h"
#import "NSString+ALHelper.h"
#import "ALDBIndexBinding.h"
#import <objc/message.h>

@implementation ALDBTableBinding (Database)

- (const aldb::SQLCreateTable)statementToCreateTable {
    aldb::SQLCreateTable stmt;
    Class cls = _modelMeta->_info.cls;
    std::string tableName = ALTableNameForModel(cls).UTF8String;
    al_guard_or_return1(!tableName.empty(), stmt,
                        @"Table name for model:\"%@\" is nil, make sure this model is bound to database!", cls);

    std::list<const aldb::ColumnDef> columns;
    for (ALDBColumnBinding *binding in self.columnBindings) {
        if (binding.columnName.UTF8String == aldb::Column::ROWID.name()) {
            continue;
        }
        columns.push_back(*binding.columnDefine);
    }
    NSArray<NSString *> *pks = al_safeInvokeSelector(NSArray *, cls, @selector(primaryKeys));
    if (pks.count > 0) {
        std::list<const aldb::IndexColumn> pkColumns;
        for (NSString *pk in pks) {
            NSString *cn = [self columnNameForProperty:pk];
            pkColumns.push_back(aldb::IndexColumn(aldb::Column(cn.UTF8String)));
        }
        stmt.create(tableName).definitions(columns, {aldb::TableConstraint().primary_key(pkColumns)});
    } else {
        stmt.create(ALTableNameForModel(cls).UTF8String).definitions(columns);
    }
    
    if (al_safeInvokeSelector(BOOL, cls, @selector(withoutRowId))) {
        stmt.without_rowid();
    }
    
    return stmt;
}

- (const aldb::SQLCreateIndex)statementToCreateIndexOnProperties:(NSArray<NSString *> *)properties isUnique:(BOOL)unique {
    ALDBIndexBinding *binding = [self indexBindingWithProperties:properties unique:unique];
    return [binding indexCreationStatement];
}

@end
