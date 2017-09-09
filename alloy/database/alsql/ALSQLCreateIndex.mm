//
//  ALSQLCreateIndex.m
//  alloy
//
//  Created by Alex Lee on 28/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALSQLCreateIndex.h"
#import "ALSQLValue.h"

@implementation ALSQLCreateIndex {
    ALSQLClause _indexNameClause;
    ALSQLClause _columnsClause;
    
    std::list<const ALDBIndexedColumn> _columns;
    std::shared_ptr<ALSQLExpr> _where;
}

- (instancetype)createIndex:(NSString *)indexName unique:(BOOL)unique ifNotExists:(BOOL)ifNotExists {
    ALSQLClause clause("CREATE ");
    clause.append(unique ? "UNIQUE INDEX " : "INDEX ").append(ifNotExists ? "IF NOT EXISTS " : "").append(indexName);
    _indexNameClause = clause;
    return self;
}

- (instancetype)onTable:(NSString *)tableName columns:(const std::list<const ALDBIndexedColumn> &)columns {
    ALSQLClause clause("ON ");
    clause.append(tableName).append(" (").append(ALSQLClause::combine<ALSQLClause>(columns, ", ")).append(")");
    _columnsClause = clause;
    return self;
}

- (instancetype)where:(const ALSQLExpr &)where {
    _where = std::shared_ptr<ALSQLExpr>(new ALSQLExpr(where));
    return self;
}

- (const ALSQLClause)SQLClause {
    ALSQLClause clause(_indexNameClause);
    clause.append(" ").append(_columnsClause);
    if (_where) {
        clause.append(" WHERE ").append(*_where);
    }
    
    return clause;
}

@end
