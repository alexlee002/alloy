//
//  sql_create_table.hpp
//  alloy
//
//  Created by Alex Lee on 01/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//
//  Fork from WCDB, github: https://github.com/tencent/wcdb
//

#ifndef sql_create_table_hpp
#define sql_create_table_hpp

#include <stdio.h>
#include "sql_statement.hpp"

namespace aldb {
class ColumnDef;
class TableConstraint;
class SQLSelect;

//@link: http://www.sqlite.org/lang_createtable.html
class SQLCreateTable : public SQLStatement {
  public:
    SQLCreateTable &create(const std::string &name, bool is_temporary = false, bool if_not_exists = true);

    template <typename T = ColumnDef>
    typename std::enable_if<std::is_base_of<ColumnDef, T>::value, SQLCreateTable &>::type
    definitions(const std::list<const T> &columns) {
        SQLClause::append(" (").append(SQLClause::combine<SQLCreateTable>(columns, ", ")).append(")");
        return *this;
    }

    template <typename T = ColumnDef, typename U = TableConstraint>
    typename std::enable_if<std::is_base_of<ColumnDef, T>::value &&
                            std::is_base_of<TableConstraint, U>::value,
                            SQLCreateTable &>::type
    definitions(const std::list<const T> &columns, const std::list<const U> &constraints) {
        SQLClause::append(" (")
            .append(SQLClause::combine<SQLCreateTable>(columns, ", "))
            .append(", ")
            .append(SQLClause::combine<SQLCreateTable>(constraints, ", "))
            .append(")");
        return *this;
    }

    SQLCreateTable &without_rowid();

    SQLCreateTable &as(const SQLSelect &select);
};
}

#endif /* sql_create_table_hpp */
