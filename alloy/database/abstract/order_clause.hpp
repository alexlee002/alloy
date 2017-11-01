//
//  order_clause.hpp
//  alloy
//
//  Created by Alex Lee on 30/09/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//
//  Fork from WCDB, github: https://github.com/tencent/wcdb
//

#ifndef order_clause_hpp
#define order_clause_hpp

#include <stdio.h>
#include "sql_clause.hpp"

namespace aldb {
class Expr;
class OrderClause : public SQLClause {
  public:
    OrderClause(const Expr &expr, OrderBy order = OrderBy::DEFAULT);
    operator std::list<const OrderClause>() const;
};
}

#endif /* order_clause_hpp */
