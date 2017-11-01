//
//  ALModelDelete.m
//  alloy
//
//  Created by Alex Lee on 11/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALModelDelete.h"
#import "sql_delete.hpp"
#import "qualified_table_name.hpp"
#import "ALActiveRecord.h"
#import "ALDBExpr.h"
#import "ALDatabase.h"
#import "NSObject+AL_Database.h"
#import "ALLogger.h"
#import "NSObject+SQLValue.h"

@implementation ALModelDelete {
    aldb::SQLDelete _statement;
    Class _modelClass;
    NSInteger _changes;
}

+ (instancetype)deleteModel:(Class)modelClass {
    ALModelDelete *instance = [[self alloc] init];
    instance->_modelClass = modelClass;
    instance->_statement.delete_from(ALTableNameForModel(modelClass).UTF8String);
    return instance;
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
    
    BOOL result = [stmt exec:_statement.values()];
    if (result) {
        _changes = [stmt changes];
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
