//
//  ALSQLInsert.m
//  alloy
//
//  Created by Alex Lee on 25/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALSQLInsert.h"
#import <BlocksKit.h>
#import "ALUtilitiesHeader.h"

@implementation ALSQLInsert {
    NSString                    *_tableName;
    ALDBConflictPolicy           _policy;
    std::list<const ALDBColumn>  _columns;
    std::list<const std::list<const ALSQLExpr>> _valuesArray;
    ALSQLSelect                 *_selectStmt;
    BOOL                         _usingDefaultValues;
}

- (instancetype)insertInto:(NSString *)tableName {
    return [self insertInto:tableName columns:{} onConflict:ALDBConflictPolicyDefault];
}

- (instancetype)insertInto:(NSString *)tableName onConflict:(ALDBConflictPolicy)policy {
    return [self insertInto:tableName columns:{} onConflict:policy];
}

- (instancetype)insertInto:(NSString *)table columns:(const std::list<const ALDBColumn> &)columns onConflict:(ALDBConflictPolicy)policy {
    _tableName = [table copy];
    _columns.insert(_columns.end(), columns.begin(), columns.end());
    _policy = policy;
    return self;
}

//- (instancetype)columnProperties:(const std::list<const ALDBColumnProperty> &)columns {
//    _columns.clear();
//    _columns.insert(_columns.end(), columns.begin(), columns.end());
//    return self;
//}

- (instancetype)values:(const std::list<const ALSQLExpr> &)exprlist {
    _valuesArray.push_back(exprlist);
    _selectStmt = nil;
    _usingDefaultValues = NO;
    return self;
}

- (instancetype)valuesWithDictionary:(NSDictionary<NSString *, id> *)dict {
    __block std::list<const ALSQLExpr> values;
    
    _columns.clear();
    [dict bk_each:^(NSString *key, id obj) {
        _columns.push_back(key);
        ALSQLExpr valExp = ALSQLExpr(obj);
        values.push_back(valExp);
    }];
    
    _valuesArray.push_back(values);
    
    _selectStmt = nil;
    _usingDefaultValues = NO;
    return self;
}

- (instancetype)valuesWithSelection:(ALSQLSelect *)select {
    _selectStmt = select;
    _valuesArray.clear();
    _usingDefaultValues = NO;
    return self;
}

- (instancetype)usingDefaultValues {
    _usingDefaultValues = YES;
    _selectStmt = nil;
    _valuesArray.clear();
    return self;
}

- (const ALSQLClause)SQLClause {
    ALSQLClause clause("INSERT ");
    
    if (_policy != ALDBConflictPolicyDefault) {
        clause.append(@"OR ").append(aldb::conflict_term((aldb::ConflictPolicy)_policy));
    }
    
    clause.append(@" INTO ").append(_tableName);
    
    if (!_columns.empty()) {
        clause.append(@" (");
        bool flag = false;
        for (auto c : _columns) {
            if (flag) {
                clause.append(@", ");
            }
            flag = true;
            
            clause.append(c.to_string());
        }
        clause.append(")");
    }
    
    if (_selectStmt != nil) {
        clause.append([_selectStmt SQLClause]);
    } else if (_usingDefaultValues){
        clause.append(@" DEFAULT VALUES");
    } else if (!_valuesArray.empty()) {
        clause.append(@" VALUES ");
        bool flag = false;
        for (auto vl : _valuesArray) {
            if (flag) {
                clause.append(@", ");
            }
            flag = true;
            ALSQLClause valuesClause = ALSQLClause::combine<ALSQLClause, ALSQLExpr>(vl, ", ");
            clause.append(@"(").append(valuesClause).append(@")");
        }
    } else if (!_columns.empty()) {
        std::string values;
        for (int i = 0; i < _columns.size(); ++i) {
            if (i > 0) {
                values.append(", ");
            }
            values.append("?");
        }
        clause.append(values);
    }
    
    return clause;
}

@end
