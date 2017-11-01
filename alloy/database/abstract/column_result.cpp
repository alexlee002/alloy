//
//  column_result.cpp
//  alloy
//
//  Created by Alex Lee on 30/09/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#include "column_result.hpp"
#include "expr.hpp"
#include "sql_value.hpp"
#include "column.hpp"

namespace aldb {
ResultColumn::ResultColumn(const Expr &expr) : SQLClause(expr) {}

ResultColumn::ResultColumn() : SQLClause() {}

ResultColumn &ResultColumn::as(const std::string &alias) {
    SQLClause::append(" AS " + alias);
    return *this;
}

ResultColumn ResultColumn::any() {
    return ResultColumn(Column::ANY);
}
    
ResultColumn ResultColumn::any(const std::string &tableName) {
    return ResultColumn(Column::ANY.in_table(tableName));
}
}
