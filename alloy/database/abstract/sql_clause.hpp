//
//  sql_clause.hpp
//  alloy
//
//  Created by Alex Lee on 29/09/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#ifndef sql_clause_hpp
#define sql_clause_hpp

#include <stdio.h>
#include <string>
#include <list>
#include "sql_value.hpp"

namespace aldb {
    
class SQLClause {
  public:
    SQLClause();
    SQLClause(const std::string &sql);
    SQLClause(const std::string &sql, const std::list<SQLValue> &values);

    SQLClause &append(const std::string &sql, const std::list<SQLValue> &values);
    SQLClause &append(const std::string &sql);
    SQLClause &append(const SQLClause &clause);

    SQLClause &reset();
    SQLClause &parenthesized();

    SQLClause &operator=(const SQLClause &clause);

    bool empty() const;

    const std::string &sql() const;
    const std::list<const SQLValue> &values() const;

    template <typename T, typename U>
    static typename std::enable_if<std::is_base_of<SQLClause, U>::value &&
                                   std::is_base_of<SQLClause, T>::value, T>::type
    combine(const std::list<const U> &clauses, const char *delimiter = nullptr) {
        T clause;
        bool flag = false;
        for (const U &u : clauses) {
            if (delimiter) {
                if (flag) {
                    clause._sql.append(delimiter);
                } else {
                    flag = true;
                }
            }
            clause.append(u);
        }
        return clause;
    }

  protected:
    SQLClause(const SQLClause &other);
    
    std::string _sql;
    std::list<const SQLValue> _values;
};
}

#endif /* sql_clause_hpp */
