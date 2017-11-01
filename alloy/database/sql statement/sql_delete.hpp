//
//  sql_delete.hpp
//  alloy
//
//  Created by Alex Lee on 01/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//
//  Fork from WCDB, github: https://github.com/tencent/wcdb
//

#ifndef sql_delete_hpp
#define sql_delete_hpp

#include <stdio.h>
#include "sql_statement.hpp"

namespace aldb {
class Expr;
class OrderClause;
class QualifiedTableName;

//@link: http://www.sqlite.org/lang_delete.html
class SQLDelete : public SQLStatement {
  public:
    SQLDelete &delete_from(const QualifiedTableName &table);
    SQLDelete &where(const Expr &where);

    template <typename T = OrderClause>
    typename std::enable_if<std::is_base_of<OrderClause, T>::value, SQLDelete &>::type
    order_by(const std::list<const T> &order_list) {
        if (!order_list.empty()) {
            SQLClause::append(" ORDER BY ").append(SQLClause::combine<SQLDelete>(order_list, ", "));
        }
        return *this;
    }

    SQLDelete &limit(const Expr &from, const Expr &to);
    SQLDelete &limit(const Expr &expr);
    SQLDelete &offset(const Expr &expr);
};
}

#endif /* sql_delete_hpp */
