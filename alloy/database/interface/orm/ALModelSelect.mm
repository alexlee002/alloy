//
//  ALModelSelect.m
//  alloy
//
//  Created by Alex Lee on 07/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALModelSelect.h"
#import "ALActiveRecord.h"
#import "ALDBExpr.h"
#import "ALDBResultSet.h"
#import "ALDatabase.h"
#import "NSObject+ALDBBindings.h"
#import "ALLogger.h"
#import "_ALModelResultEnumerator.h"
#import "ALDBStatement+orm_Private.h"
#import "ALModelORMBase+Private.h"

@implementation ALModelSelect {
    aldb::SQLSelect _statement;
    std::shared_ptr<ALDBResultColumnList> _resultColumns;
}

- (instancetype)initWithDatabase:(ALDBHandle *)handle
                           table:(NSString *)table
                      modelClass:(Class)modelClass
                      properties:(const ALDBResultColumnList &)results {
    self = [self init];
    if (self) {
        _database = handle;
        _statement.select(results, results.isDistinct()).from(table.UTF8String);
        _modelClass    = modelClass;
        _resultColumns = std::make_shared<ALDBResultColumnList>(results);
    }
    return self;
}

+ (instancetype)selectModel:(Class)modelClass properties:(const ALDBResultColumnList &)results {
    return [[self alloc] initWithDatabase:[modelClass al_database]
                                    table:ALTableNameForModel(modelClass)
                               modelClass:modelClass
                               properties:results];
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
    NSError *error = nil;
    ALDBStatement *stmt = [_database prepare:_statement error:&error];
    if (!stmt && error) {
        ALLogError(@"%@", error);
        return nil;
    }
    stmt.modelSelect = self;
    return stmt;
}

- (nullable ALDBResultSet *)executeQuery {
    return [[self preparedStatement] query];
}

- (nullable NSEnumerator *)objectEnumerator {
    return [_ALModelResultEnumerator enumeratorWithModel:_modelClass
                                               resultSet:[self executeQuery]
                                           resultColumns:*_resultColumns];
}

- (nullable NSArray *)allObjects {
    NSMutableArray *arr = [NSMutableArray array];
    for (id obj in [self objectEnumerator]) {
        [arr addObject:obj];
    }
    return [arr copy];
}

@end
