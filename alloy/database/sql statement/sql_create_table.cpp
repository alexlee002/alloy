//
//  sql_create_table.cpp
//  alloy
//
//  Created by Alex Lee on 01/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#include "sql_create_table.hpp"
#include "column_def.hpp"
#include "table_constraint.hpp"
#include "sql_select.hpp"

namespace aldb {
SQLCreateTable &SQLCreateTable::create(const std::string &name, bool is_temporary, bool if_not_exists) {
    SQLClause::append("CREATE ");
    if (is_temporary) {
        SQLClause::append("TEMPORARY ");
    }
    SQLClause::append("TABLE ");

    if (if_not_exists) {
        SQLClause::append("IF NOT EXISTS ");
    }
    SQLClause::append(name);

    return *this;
}

SQLCreateTable &SQLCreateTable::without_rowid() {
    SQLClause::append(" WITHOUT ROWID");
    return *this;
}

SQLCreateTable &SQLCreateTable::as(const SQLSelect &select) {
    SQLClause::append(" AS ").append(select);
    return *this;
}
}
