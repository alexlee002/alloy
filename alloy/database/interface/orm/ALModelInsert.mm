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
#import "NSObject+ALDBBindings.h"
#import "ALLogger.h"
#import "NSObject+SQLValue.h"
#import "_ALModelHelper+cxx.h"
#import "ALModelORMBase+Private.h"

@implementation ALModelInsert {
    aldb::SQLInsert _statement;
    ALDBPropertyList _columns;
    NSInteger _changes;
}

+ (instancetype)insertModel:(Class)modelClass
                 properties:(const ALDBPropertyList &)propertiesToSave
                 onConflict:(ALDBConflictPolicy)onConflict {
    return [[self alloc] initWithDatabase:[modelClass al_database]
                                    table:ALTableNameForModel(modelClass)
                               modelClass:modelClass
                               properties:propertiesToSave
                               onConflict:onConflict];
}

- (instancetype)initWithDatabase:(ALDBHandle *)handle
                           table:(NSString *)table
                      modelClass:(Class)modelClass
                      properties:(const ALDBPropertyList &)propertiesToSave
                      onConflict:(ALDBConflictPolicy)onConflict {
    self = [self init];
    if (self) {
        _database   = handle;
        _modelClass = modelClass;
        _statement
            .insert(ALTableNameForModel(modelClass).UTF8String, propertiesToSave, (aldb::ConflictPolicy) onConflict)
            .values(std::list<const aldb::Expr>(propertiesToSave.size(), aldb::Expr::BIND_PARAM));
    }
    return self;
}

- (NSInteger)changes {
    return _changes;
}

- (nullable ALDBStatement *)preparedStatement {
    NSError *error = nil;
    ALDBStatement *stmt = [_database prepare:_statement error:&error];
    if (!stmt && error) {
        _changes = 0;
        ALLogError(@"%@", error);
        return nil;
    }
    return stmt;
}

- (BOOL)executeWithObjects:(NSArray *)models {
    if (models.count == 0) {
        return NO;
    }
    
    NSError *error = nil;
    BOOL ret = [_database inTransaction:^(BOOL * _Nonnull rollback) {
        _changes = 0;
        ALDBStatement *stmt = [self preparedStatement];
        if (!stmt) {
            *rollback = YES;
            return;
        }
        
        for (id model in models) {
            if ([model class] != _modelClass) {
                ALAssert(NO, @"Expected model class is: %@, but was: %@.", _modelClass, [model class]);
                continue;
            }
            
            std::list<const aldb::SQLValue> values;
            for (auto p : _columns) {
                ALDBColumnBinding *binding = p.columnBinding();
                
                id value = nil;
                if (![model al_autoIncrement] || !_ALIsAutoIncrementColumn(binding)) {
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
    } error:&error];
    
    if (!ret && error) {
        ALLogError(@"%@", error);
    }
    return ret;
}

@end
