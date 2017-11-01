//
//  sql_drop_table.cpp
//  alloy
//
//  Created by Alex Lee on 01/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#include "sql_drop.hpp"

namespace aldb {

SQLDropTable &SQLDropTable::drop(const std::string &table, bool if_exists) {
    SQLClause::append("DROP TABLE ");
    if (if_exists) {
        SQLClause::append("IF EXISTS ");
    }
    SQLClause::append(table);
    return *this;
}

    SQLDropIndex &SQLDropIndex::drop(const std::string &index, bool if_exists) {
    SQLClause::append("DROP INDEX ");
    if (if_exists) {
        SQLClause::append("IF EXISTS ");
    }
    SQLClause::append(index);
    return *this;
}

SQLDropTrigger &SQLDropTrigger::drop(const std::string &trigger, bool if_exists) {
    SQLClause::append("DROP TRIGGER ");
    if (if_exists) {
        SQLClause::append("IF EXISTS ");
    }
    SQLClause::append(trigger);
    return *this;
}

SQLDropView &SQLDropView::drop(const std::string &view, bool if_exists) {
    SQLClause::append("DROP VIEW ");
    if (if_exists) {
        SQLClause::append("IF EXISTS ");
    }
    SQLClause::append(view);
    return *this;
}
}
