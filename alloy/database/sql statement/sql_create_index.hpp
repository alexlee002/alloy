//
//  sql_create_index.hpp
//  alloy
//
//  Created by Alex Lee on 01/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//
//  Fork from WCDB, github: https://github.com/tencent/wcdb
//

#ifndef sql_create_index_hpp
#define sql_create_index_hpp

#include <stdio.h>
#include "sql_statement.hpp"

namespace aldb {
class IndexColumn;
class Expr;

//@link: http://www.sqlite.org/lang_createindex.html
class SQLCreateIndex : public SQLStatement {
  public:
    SQLCreateIndex &create(const std::string &index_name, bool unique = false, bool if_not_exists = true);

    template <typename T = IndexColumn>
    typename std::enable_if<std::is_base_of<IndexColumn, T>::value, SQLCreateIndex &>::type
    on(const std::string &table, const std::list<const T> &indexes) {
        SQLClause::append(" ON " + table + "(").append(SQLClause::combine<SQLCreateIndex>(indexes, ", ")).append(")");
        return *this;
    }

    SQLCreateIndex &where(const Expr &expr);
};
}

#endif /* sql_create_index_hpp */
