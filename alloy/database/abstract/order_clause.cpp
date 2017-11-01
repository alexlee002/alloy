//
//  order_clause.cpp
//  alloy
//
//  Created by Alex Lee on 30/09/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#include "order_clause.hpp"
#include "expr.hpp"

namespace aldb {
OrderClause::OrderClause(const Expr &expr, OrderBy order) : SQLClause(expr) {
    if (order != OrderBy::DEFAULT) {
        SQLClause::append(" ").append(aldb::order_term(order));
    }
}

OrderClause::operator std::list<const OrderClause>() const { return {*this}; }
}
