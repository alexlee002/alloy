//
//  sql_create_view.cpp
//  alloy
//
//  Created by Alex Lee on 02/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#include "sql_create_view.hpp"
#include "sql_select.hpp"

namespace aldb {
SQLCreateView &SQLCreateView::create(const std::string &name, bool temporary, bool if_not_exists) {
    SQLClause::append("CREATE ");

    if (temporary) {
        SQLClause::append("TEMPORARY ");
    }

    SQLClause::append("VIEW ");

    if (if_not_exists) {
        SQLClause::append("IF NOT EXISTS ");
    }
    SQLClause::append(name);
    return *this;
}

SQLCreateView &SQLCreateView::columns(const std::list<std::string> &column_names) {
    SQLClause::append("(");

    bool flag = false;
    for (auto col : column_names) {
        if (flag) {
            SQLClause::append(", ");
        } else {
            flag = true;
        }
        SQLClause::append(col);
    }
    SQLClause::append(")");

    return *this;
}

SQLCreateView &SQLCreateView::as(const SQLSelect &select) {
    SQLClause::append(" AS ").append(select);
    return *this;
}
}
