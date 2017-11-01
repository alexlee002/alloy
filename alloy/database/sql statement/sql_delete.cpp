//
//  sql_delete.cpp
//  alloy
//
//  Created by Alex Lee on 01/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#include "sql_delete.hpp"
#include "expr.hpp"
#include "order_clause.hpp"
#include "qualified_table_name.hpp"

namespace aldb {

SQLDelete &SQLDelete::delete_from(const QualifiedTableName &table) {
    SQLClause::append("DELETE FROM ").append(table);
    return *this;
}

SQLDelete &SQLDelete::where(const Expr &where) {
    if (!where.empty()) {
        SQLClause::append(" WHERE ").append(where);
    }
    return *this;
}

SQLDelete &SQLDelete::limit(const Expr &offset, const Expr &limit) {
    if (!offset.empty()) {
        SQLClause::append(" LIMIT ").append(offset);
        if (!limit.empty()) {
            SQLClause::append(", ").append(limit);
        }
    }
    return *this;
}

SQLDelete &SQLDelete::limit(const Expr &limit) {
    if (!limit.empty()) {
        SQLClause::append(" LIMIT ").append(limit);
    }
    return *this;
}

SQLDelete &SQLDelete::offset(const Expr &offset) {
    if (!offset.empty()) {
        SQLClause::append(" OFFSET ").append(offset);
    }
    return *this;
}
}
