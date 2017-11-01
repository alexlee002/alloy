//
//  ALModelUpdate.m
//  alloy
//
//  Created by Alex Lee on 10/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALModelUpdate.h"
#import "sql_update.hpp"
#import "ALActiveRecord.h"
#import "ALDBExpr.h"
#import "ALDatabase.h"
#import "qualified_table_name.hpp"
#import "NSObject+AL_Database.h"
#import "ALLogger.h"
#import "ALDBColumnBinding.h"
#import "_ALModelHelper+cxx.h"
#import "NSObject+SQLValue.h"

@implementation ALModelUpdate {
    aldb::SQLUpdate _statement;
    ALDBPropertyList _columns;
    Class _modelClass;
    NSInteger _changes;
    ALDBConflictPolicy _conflictPolicy;
}

+ (instancetype)updateModel:(Class)modelClass
                 properties:(const ALDBPropertyList &)propertiesToUpdate
                 onConflict:(ALDBConflictPolicy)onConflict {
    ALModelUpdate *update = [[self alloc] init];
    update->_modelClass = modelClass;
    update->_conflictPolicy = onConflict;
    update->_columns.insert(update->_columns.begin(), propertiesToUpdate.begin(), propertiesToUpdate.end());
    
    std::list<const std::pair<const aldb::UpdateColumns, const ALDBExpr>>list;
    for (auto p : propertiesToUpdate) {
        list.push_back({p, ALDBExpr::BIND_PARAM});
    }
    update->_statement.update(ALTableNameForModel(modelClass).UTF8String, (aldb::ConflictPolicy)onConflict).set(list);
    return update;
}

- (instancetype)where:(const ALDBCondition &)condition {
    _statement.where(condition);
    return self;
}

- (instancetype)orderBy:(const std::list<const aldb::OrderClause> &)list {
    _statement.order_by(list);
    return self;
}

- (instancetype)limit:(const ALDBExpr &)limit {
    _statement.limit(limit);
    return self;
}

- (instancetype)offset:(const ALDBExpr &)offset {
    _statement.offset(offset);
    return self;
}

- (BOOL)executeWithObject:(id)model {
    if (model == nil) {
        return NO;
    }
    al_guard_or_return([model class] == _modelClass, NO);
    
    ALDBStatement *stmt = [self preparedStatement];
    if (!stmt) {
        return NO;
    }
    std::list<const aldb::SQLValue> values;
    for (auto p : _columns) {
        ALDBColumnBinding *binding = p.columnBinding();
        id value = _ALColumnValueForModelProperty(model, binding);
        values.push_back([value al_SQLValue]);
    }
    values.insert(values.end(), _statement.values().begin(), _statement.values().end());
    
    BOOL result = [stmt exec:values];
    if (result) {
        _changes = [stmt changes];
        //TODO: do some test to decide the following lines are needed or not
//        if (_conflictPolicy == ALDBConflictPolicyReplace) {
//             [model al_setRowid:stmt.lastInsertRowId];
//        }
    }
    return result;
}

- (NSInteger)changes {
    return _changes;
}

- (nullable ALDBStatement *)preparedStatement {
    ALDatabase *database = [_modelClass al_database];
    NSError *error = nil;
    ALDBStatement *stmt = [database prepare:_statement error:&error];
    if (!stmt && error) {
        _changes = 0;
        ALLogError(@"%@", error);
        return nil;
    }
    return stmt;
}

@end
