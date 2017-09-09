//
//  ALSQLDelete.m
//  alloy
//
//  Created by Alex Lee on 26/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALSQLDelete.h"

@implementation ALSQLDelete {
    NSString *_qualifiedTableName;
    
    ALSQLExpr   _where;
    ALSQLClause _orderBy;
    ALSQLClause _offset;
    ALSQLClause _limit;
}

- (instancetype)deleteFrom:(NSString *)tableName {
    _qualifiedTableName = [tableName copy];
    return self;
}

- (instancetype)where:(const ALDBCondition &)conditions {
    _where = _where && conditions;
    return self;
}

- (instancetype)orderBy:(const std::list<const ALSQLExpr> &)exprlist {
    for (auto expr : exprlist) {
        if (!_orderBy.is_empty()) {
            _orderBy.append(@", ");
        }
        _orderBy.append(expr);
    }
    return self;
}

- (instancetype)limit:(const ALSQLExpr &)limit {
    _limit = limit;
    return self;
}

- (instancetype)offset:(const ALSQLExpr &)offset {
    _offset = offset;
    return self;
}

- (const ALSQLClause)SQLClause {
    ALSQLClause clause("DELETE FROM ");
    clause.append(_qualifiedTableName);
    
    if (!_where.is_empty()) {
        clause.append(" WHERE ").append(_where);
    }
    
    if (!_orderBy.is_empty()) {
        clause.append(" ORDER BY ").append(_orderBy);
    }
    
    if (!_limit.is_empty()) {
        clause.append(" LIMIT ").append(_limit);
    }
    
    if (!_offset.is_empty()) {
        clause.append(" OFFSET ").append(_offset);
    }
    return clause;
}

@end
