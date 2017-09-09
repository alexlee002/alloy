//
//  ALDBIndexedColumn.m
//  alloy
//
//  Created by Alex Lee on 27/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDBIndexedColumn.h"
#import "ALSQLValue.h"

ALDBIndexedColumn::ALDBIndexedColumn():ALSQLClause() {}

ALDBIndexedColumn::ALDBIndexedColumn(const ALDBColumn &column, const char *collate, ALDBOrder order)
    : ALSQLClause(column.to_string()) {
    if (collate && strlen(collate) > 0) {
        ALSQLClause::append(" COLLATE ").append(collate);
    }
    if (order != ALDBOrderDefault) {
        ALSQLClause::append(aldb::order_term((aldb::OrderBy) order));
    }
}

ALDBIndexedColumn::ALDBIndexedColumn(const ALSQLExpr &expr, const char *collate, ALDBOrder order) : ALSQLClause(expr) {
    if (collate && strlen(collate) > 0) {
        ALSQLClause::append(" COLLATE ").append(collate);
    }
    if (order != ALDBOrderDefault) {
        ALSQLClause::append(aldb::order_term((aldb::OrderBy) order));
    }
}
