//
//  column_index.cpp
//  alloy
//
//  Created by Alex Lee on 30/09/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#include "column_index.hpp"
#include "column.hpp"
#include "expr.hpp"
#include "sql_value.hpp"

namespace aldb {
IndexColumn::IndexColumn(const Column &column, const std::string &collate, OrderBy order) : SQLClause(column.name()) {
    if (!collate.empty()) {
        SQLClause::append(" COLLATE ").append(collate);
    }

    if (order != OrderBy::DEFAULT) {
        SQLClause::append(" " + aldb::order_term(order));
    }
}

IndexColumn::IndexColumn(const Expr &expr, const std::string &collate, OrderBy order) : SQLClause(expr) {
    if (!collate.empty()) {
        SQLClause::append(" COLLATE ").append(collate);
    }

    if (order != OrderBy::DEFAULT) {
        SQLClause::append(" " + aldb::order_term(order));
    }
}

IndexColumn::operator std::list<const IndexColumn>() const {
    return {*this};
}
}
