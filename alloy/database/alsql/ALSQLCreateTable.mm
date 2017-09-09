//
//  ALSQLCreateTable.m
//  alloy
//
//  Created by Alex Lee on 26/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALSQLCreateTable.h"

@implementation ALSQLCreateTable {
    NSString *_tableName;
    BOOL _isTmpTable;
    BOOL _ifNotExists;
    std::list<const ALDBColumnDefine> _conlums;
    std::list<const ALDBTableConstraint> _constraints;
    BOOL _withoutRowId;
}

- (instancetype)createTable:(NSString *)table {
    return [self createTable:table ifNotExists:YES isTemperate:NO];
}

- (instancetype)createTable:(NSString *)table ifNotExists:(BOOL)ifNotExists isTemperate:(BOOL)isTmpTable {
    _tableName = [table copy];
    _isTmpTable = isTmpTable;
    _ifNotExists = ifNotExists;
    return self;
}

- (instancetype)columnDefines:(const std::list<const ALDBColumnDefine> &)columnDefs {
    _conlums.insert(_conlums.end(), columnDefs.begin(), columnDefs.end());
    return self;
}

- (instancetype)constraints:(const std::list<const ALDBTableConstraint> &)constraints {
    _constraints.insert(_constraints.end(), constraints.begin(), constraints.end());
    return self;
}

- (instancetype)withoutRowId:(BOOL)yesOrNo {
    _withoutRowId = yesOrNo;
    return self;
}

- (const ALSQLClause)SQLClause {
    ALSQLClause clause("CREATE ");
    if (_isTmpTable) {
        clause.append("TEMP ");
    }
    clause.append("TABLE ");
    
    if (_ifNotExists) {
        clause.append("IF NOT EXISTS ");
    }
    clause.append(_tableName);

    clause.append("(");
    
    size_t col_count = _conlums.size();
    if (col_count > 0) {
        size_t num = 0;
        for (auto c : _conlums) {
            clause.append(ALSQLClause(c));
            if (++num < col_count) {
                clause.append(", ");
            }
        }
        
        if (_constraints.size() > 0) {
            clause.append(", ").append(ALSQLClause::combine<ALSQLClause>(_constraints, ", "));
        }
    }
    clause.append(")");
    
    if (_withoutRowId) {
        clause.append(" WITHOUT ROWID");
    }

    return clause;
}

@end
