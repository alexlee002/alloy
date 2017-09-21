//
//  ALSQLUpdate.m
//  alloy
//
//  Created by Alex Lee on 25/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALSQLUpdate.h"
#import <BlocksKit.h>
#import "defines.hpp"

@implementation ALSQLUpdate {
    NSString *_qualifiedTableName;
    ALDBConflictPolicy _policy;
    ALSQLClause _setClause;
    ALSQLExpr   _where;
    ALSQLClause _orderBy;
    ALSQLClause _offset;
    ALSQLClause _limit;
}

- (instancetype)update:(NSString *)tableName {
    return [self update:tableName onConflict:ALDBConflictPolicyDefault];
}

- (instancetype)update:(NSString *)tableName onConflict:(ALDBConflictPolicy)policy {
    _qualifiedTableName = [tableName copy];
    _policy = policy;
    return self;
}

- (instancetype)set:(const std::list<const std::pair<const ALDBColumn, const ALSQLExpr>> &)values {
    for(auto kv : values) {
        if (!_setClause.is_empty()) {
            _setClause.append(@", ");
        }
        _setClause.append(ALSQLExpr(kv.first) == kv.second);
    }
    return self;
}

- (instancetype)setValuesWithDictionary:(NSDictionary<NSString *, id> *)values {
    [values bk_each:^(NSString *key, id obj) {
        if (!_setClause.is_empty()) {
            _setClause.append(@", ");
        }
        _setClause.append(ALSQLExpr(ALDBColumn(key)) == obj);
    }];
    return self;
}

- (instancetype)columns:(const /*std::list<const ALDBColumn>*/ALDBColumnList &)columns {
    _setClause = ALSQLClause();
    for (auto c : columns) {
        if (!_setClause.is_empty()) {
            _setClause.append(", ");
        }
        _setClause.append(c.to_string()).append(" = ?");
    }
    return self;
}

//- (instancetype)columnProperties:(const std::list<const ALDBColumnProperty> &)columns {
//    _setClause = ALSQLClause();
//    for (auto c : columns) {
//        _setClause.append(c.to_string());
//        _setClause.append(" = ?");
//    }
//    return self;
//}

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
    ALSQLClause clause("UPDATE ");
    if (_policy != ALDBConflictPolicyDefault) {
        clause.append(@"OR ");
        clause.append(aldb::conflict_term((aldb::ConflictPolicy)_policy));
    }
    
    clause.append([@" " stringByAppendingString:_qualifiedTableName]);
    
    clause.append(@" SET ").append(_setClause);
    
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
