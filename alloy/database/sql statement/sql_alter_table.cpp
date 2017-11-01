//
//  sql_alter_table.cpp
//  alloy
//
//  Created by Alex Lee on 01/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#include "sql_alter_table.hpp"
#include "column_def.hpp"

namespace aldb {
SQLAlterTable &SQLAlterTable::alter(const std::string &table) {
    SQLClause::append("ALTER TABLE " + table);
    return *this;
}

SQLAlterTable &SQLAlterTable::rename(const std::string &new_name) {
    SQLClause::append(" RENAME TO " + new_name);
    return *this;
}

SQLAlterTable &SQLAlterTable::add_column(const ColumnDef &column) {
    SQLClause::append(" ADD COLUMN ").append(column);
    return *this;
}
}
