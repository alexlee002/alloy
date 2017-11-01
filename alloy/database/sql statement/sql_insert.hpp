//
//  sql_insert.hpp
//  alloy
//
//  Created by Alex Lee on 30/09/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//
//  Fork from WCDB, github: https://github.com/tencent/wcdb
//

#ifndef sql_insert_hpp
#define sql_insert_hpp

#include <stdio.h>
#include "sql_statement.hpp"
#include "defines.hpp"

namespace aldb {
class Expr;
class Column;
class SQLSelect;

//@link: http://www.sqlite.org/lang_insert.html
class SQLInsert : public SQLStatement {
  public:
    SQLInsert &insert(const std::string &table, ConflictPolicy conflict = ConflictPolicy::DEFAULT);

    template <typename T = Column>
    typename std::enable_if<std::is_base_of<Column, T>::value, SQLInsert &>::type
    insert(const std::string &table,
           const std::list<const T> &columns,
           ConflictPolicy conflict = ConflictPolicy::DEFAULT) {
        
        SQLClause::append("INSERT");
        if (conflict != ConflictPolicy::DEFAULT) {
            SQLClause::append(" OR ").append(aldb::conflict_term(conflict));
        }
        SQLClause::append(" INTO " + table);
        if (!columns.empty()) {
            SQLClause::append("(").append(SQLClause::combine<SQLInsert>(columns, ", ")).append(")");
        }
        return *this;
    }

    template <typename T = Expr>
    typename std::enable_if<std::is_base_of<Expr, T>::value, SQLInsert &>::type
    values(const std::list<const T> &values) {
        if (!values.empty()) {
            SQLClause::append(" VALUES (").append(SQLClause::combine<SQLInsert>(values, ", ")).append(")");
        }
        return *this;
    }
    
    SQLInsert &values(const SQLSelect &select);
    
    //using default values;
    SQLInsert &values(const std::nullptr_t &default_values);
};
}

#endif /* sql_insert_hpp */
