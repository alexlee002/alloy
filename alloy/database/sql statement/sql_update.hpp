//
//  sql_update.hpp
//  alloy
//
//  Created by Alex Lee on 30/09/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//
//  Fork from WCDB, github: https://github.com/tencent/wcdb
//

#ifndef sql_update_hpp
#define sql_update_hpp

#include <stdio.h>
#include "sql_statement.hpp"
#include "defines.hpp"

namespace aldb {
class Expr;
class Column;
class OrderClause;
class QualifiedTableName;

class UpdateColumns : public SQLClause {
  public:
    UpdateColumns(const Column &column);

    template <typename T = Column>
    UpdateColumns(const std::list<const T> &columns,
                  typename std::enable_if<std::is_base_of<Column, T>::value>::type * = nullptr) {
        if (columns.size() > 1) {
            SQLClause::append("(").append(SQLClause::combine<UpdateColumns>(columns, ", ")).append(")");
        } else if (!columns.empty()) {
            SQLClause::append(columns[0]);
        }
    }
    
    operator aldb::Column() const;
};

//@link: http://www.sqlite.org/lang_update.html
class SQLUpdate : public SQLStatement {
  public:
    SQLUpdate &update(const QualifiedTableName &table, ConflictPolicy conflict = ConflictPolicy::DEFAULT);

    template <typename T, typename U>
    typename std::enable_if<std::is_base_of<UpdateColumns, T>::value &&
                            std::is_base_of<Expr, U>::value,
                            SQLUpdate &>::type
    set(const std::list<const std::pair<const T, const U>> &values) {
        SQLClause::append(" SET ");

        bool flag = false;
        for (const auto &value : values) {
            if (flag) {
                SQLClause::append(", ");
            } else {
                flag = true;
            }
            SQLClause::append(Expr(Column(value.first)) == value.second);
        }
        return *this;
    }

    SQLUpdate &where(const Expr &where);

    template <typename T = OrderClause>
    typename std::enable_if<std::is_base_of<OrderClause, T>::value, SQLUpdate &>::type
    order_by(const std::list<const T> &order_list) {
        if (!order_list.empty()) {
            SQLClause::append(" ORDER BY ").append(SQLClause::combine<SQLUpdate>(order_list, ", "));
        }
        return *this;
    }

    SQLUpdate &limit(const Expr &offset, const Expr &limit);
    SQLUpdate &limit(const Expr &limit);
    SQLUpdate &offset(const Expr &offset);
};
}

#endif /* sql_update_hpp */
