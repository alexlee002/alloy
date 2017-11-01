//
//  sql_create_index.cpp
//  alloy
//
//  Created by Alex Lee on 01/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#include "sql_create_index.hpp"
#include "column_index.hpp"
#include "expr.hpp"

namespace aldb {
SQLCreateIndex &SQLCreateIndex::create(const std::string &index_name, bool unique, bool if_not_exists) {
    SQLClause::append("CREATE ");
    if (unique) {
        SQLClause::append("UNIQUE ");
    }

    SQLClause::append("INDEX ");

    if (if_not_exists) {
        SQLClause::append("IF NOT EXISTS ");
    }

    SQLClause::append(index_name);
    return *this;
}

SQLCreateIndex &SQLCreateIndex::where(const Expr &expr) {
    if (!expr.empty()) {
        SQLClause::append(" WHERE ").append(expr);
    }
    return *this;
}
}
