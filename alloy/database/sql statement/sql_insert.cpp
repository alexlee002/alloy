//
//  sql_insert.cpp
//  alloy
//
//  Created by Alex Lee on 30/09/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#include "sql_insert.hpp"
#include "expr.hpp"
#include "column.hpp"
#include "sql_select.hpp"

namespace aldb {
SQLInsert &SQLInsert::insert(const std::string &table, ConflictPolicy conflict) {
    SQLClause::append("INSERT");
    if (conflict != ConflictPolicy::DEFAULT) {
        SQLClause::append(" OR ").append(aldb::conflict_term(conflict));
    }
    SQLClause::append(" INTO " + table);
    return *this;
}

SQLInsert &SQLInsert::values(const SQLSelect &select) {
    SQLClause::append(" ").append(select);
    return *this;
}

SQLInsert &SQLInsert::values(const std::nullptr_t &default_values) {
    SQLClause::append(" DEFAULT VALUES");
    return *this;
}
}
