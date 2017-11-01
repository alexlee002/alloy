//
//  sql_select.cpp
//  alloy
//
//  Created by Alex Lee on 30/09/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#include "sql_select.hpp"
#include "column_result.hpp"
#include "expr.hpp"
#include "order_clause.hpp"

namespace aldb {
SQLSelect &SQLSelect::from(const std::string &table) {
    SQLClause::append(" FROM " + table);
    return *this;
}

SQLSelect &SQLSelect::where(const Expr &where) {
    if (!where.empty()) {
        SQLClause::append(" WHERE ").append(where);
    }
    return *this;
}

SQLSelect &SQLSelect::having(const Expr &having) {
    if (!having.empty()) {
        SQLClause::append(" HAVING ").append(having);
    }
    return *this;
}

SQLSelect &SQLSelect::limit(const Expr &offset, const Expr &limit) {
    if (!offset.empty()) {
        SQLClause::append(" LIMIT ").append(offset);
        if (!limit.empty()) {
            SQLClause::append(", ").append(limit);
        }
    }
    return *this;
}

SQLSelect &SQLSelect::limit(const Expr &limit) {
    if (!limit.empty()) {
        SQLClause::append(" LIMIT ").append(limit);
    }
    return *this;
}

SQLSelect &SQLSelect::offset(const Expr &offset) {
    if (!offset.empty()) {
        SQLClause::append(" OFFSET ").append(offset);
    }
    return *this;
}
}
