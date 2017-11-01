//
//  sql_select.hpp
//  alloy
//
//  Created by Alex Lee on 30/09/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//
//  Fork from WCDB, github: https://github.com/tencent/wcdb
//

#ifndef sql_select_hpp
#define sql_select_hpp

#include <stdio.h>
#include "sql_statement.hpp"

namespace aldb {
class ResultColumn;
class Expr;
class OrderClause;

//@link: http://www.sqlite.org/lang_select.html
class SQLSelect : public SQLStatement {
  public:
    template <typename T = ResultColumn>
    typename std::enable_if<std::is_base_of<ResultColumn, T>::value, SQLSelect &>::type
    select(const std::list<const T> &result_columns, bool distinct = false) {
        SQLClause::append("SELECT ");
        if (distinct) {
            SQLClause::append("DISTINCT ");
        }
        SQLClause::append(SQLClause::combine<SQLSelect>(result_columns, ", "));
        return *this;
    }

    SQLSelect &from(const std::string &table);

    SQLSelect &where(const Expr &where);

    template <typename T = Expr>
    typename std::enable_if<std::is_base_of<Expr, T>::value, SQLSelect &>::type
    group_by(const std::list<const T> &group_list) {
        if (!group_list.empty()) {
            SQLClause::append(" GROUP BY ").append(SQLClause::combine<SQLSelect>(group_list, ", "));
        }
        return *this;
    }

    SQLSelect &having(const Expr &having);

    template <typename T = OrderClause>
    typename std::enable_if<std::is_base_of<OrderClause, T>::value, SQLSelect &>::type
    order_by(const std::list<const T> &order_list) {
        if (!order_list.empty()) {
            SQLClause::append(" ORDER BY ").append(SQLClause::combine<SQLSelect>(order_list, ", "));
        }
        return *this;
    }

    SQLSelect &limit(const Expr &offset, const Expr &limit);
    SQLSelect &limit(const Expr &limit);
    SQLSelect &offset(const Expr &offset);
};
}

#endif /* sql_select_hpp */
