//
//  ALModelSelect.m
//  alloy
//
//  Created by Alex Lee on 07/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALModelSelect+Private.h"
#import "ALActiveRecord.h"
#import "ALDBExpr.h"
#import "ALDBResultSet.h"
#import "ALDatabase.h"
#import "NSObject+AL_Database.h"
#import "ALLogger.h"
#import "_ALModelResultEnumerator.h"
#import "ALDBStatement+orm_Private.h"

@implementation ALModelSelect 

+ (instancetype)selectModel:(Class)modelClass properties:(const ALDBResultColumnList &)results{
    ALModelSelect *select = [[self alloc] init];
    select->_statement.select(results, results.isDistinct()).from(ALTableNameForModel(modelClass).UTF8String);
    select->_modelClass = modelClass;
    select->_resultColumns = std::make_shared<ALDBResultColumnList>(results);
    return select;
}

- (instancetype)where:(const ALDBCondition &)condition {
    _statement.where(condition);
    return self;
}

- (instancetype)groupBy:(const std::list<const ALDBExpr> &)list {
    _statement.group_by(list);
    return self;
}

- (instancetype)having:(const ALDBExpr &)expr {
    _statement.having(expr);
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

- (nullable ALDBStatement *)preparedStatement {
    ALDatabase *database = [_modelClass al_database];
    NSError *error = nil;
    ALDBStatement *stmt = [database prepare:_statement error:&error];
    if (!stmt && error) {
        ALLogError(@"%@", error);
        return nil;
    }
    stmt.modelSelect = self;
    return stmt;
}

- (nullable NSEnumerator *)objectEnumerator {
    ALDatabase *database = [_modelClass al_database];
    NSError *error = nil;
    ALDBResultSet *rs = [database query:_statement error:&error];
    if (!rs && error) {
        ALLogError(@"%@", error);
        return nil;
    }
    return [_ALModelResultEnumerator enumeratorWithModel:_modelClass resultSet:rs resultColumns:*_resultColumns];
}

- (nullable NSArray *)allObjects {
    NSMutableArray *arr = [NSMutableArray array];
    for (id obj in [self objectEnumerator]) {
        [arr addObject:obj];
    }
    return [arr copy];
}

@end
