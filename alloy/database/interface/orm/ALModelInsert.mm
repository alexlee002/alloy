//
//  ALModelInsert.m
//  alloy
//
//  Created by Alex Lee on 11/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALModelInsert.h"
#import "sql_insert.hpp"
#import "ALActiveRecord.h"
#import "ALDBExpr.h"
#import "ALDatabase.h"
#import "NSObject+AL_Database.h"
#import "ALLogger.h"
#import "NSObject+SQLValue.h"
#import "ALDatabase+Core.h"
#import "_ALModelHelper+cxx.h"

@implementation ALModelInsert {
    aldb::SQLInsert _statement;
    ALDBPropertyList _columns;
    Class _modelClass;
    NSInteger _changes;
}

+ (instancetype)insertModel:(Class)modelClass
                 properties:(const ALDBPropertyList &)propertiesToSave
                 onConflict:(ALDBConflictPolicy)onConflict {
    ALModelInsert *instance = [[self alloc] init];
    instance->_modelClass   = modelClass;
    instance->_columns.insert(instance->_columns.begin(), propertiesToSave.begin(), propertiesToSave.end());
    instance->_statement.insert(ALTableNameForModel(modelClass).UTF8String, propertiesToSave, (aldb::ConflictPolicy) onConflict)
        .values(std::list<const aldb::Expr>(propertiesToSave.size(), aldb::Expr::BIND_PARAM));
    
    return instance;
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

- (BOOL)executeWithObjects:(NSArray *)models {
    ALDatabase *database = [_modelClass al_database];
    return [database inTransaction:^(BOOL * _Nonnull rollback) {
        _changes = 0;
        ALDBStatement *stmt = [self preparedStatement];
        if (!stmt) {
            return;
        }
        for (id model in models) {
            al_guard_or_return([model class] == _modelClass, AL_VOID);
            
            std::list<const aldb::SQLValue> values;
            for (auto p : _columns) {
                ALDBColumnBinding *binding = p.columnBinding();
                
                id value = nil;
                if (![model al_autoIncrement] || !_ALISAutoIncrementColumn(binding)) {
                    value = _ALColumnValueForModelProperty(model, binding);
                }
                values.push_back([value al_SQLValue]);
            }
            
            BOOL result = [stmt exec:values];
            if (result) {
                _changes += [stmt changes];
                [model al_setRowid:stmt.lastInsertRowId];
            } else {
                // break and rollback if error occured
                *rollback = YES;
                _changes = 0;
                return;
            }
        }
    } error:nil];
}

@end
