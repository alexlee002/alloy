//
//  sql_attach.cpp
//  alloy
//
//  Created by Alex Lee on 02/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//
//  Fork from WCDB, github: https://github.com/tencent/wcdb
//

#include "expr.hpp"
#include "sql_attach.hpp"

namespace aldb {

SQLAttach &SQLAttach::attach(const Expr &expr) {
    SQLClause::append("ATTACH ").append(expr);
    return *this;
}

SQLAttach &SQLAttach::as(const std::string &schema) {
    SQLClause::append(" AS " + schema);
    return *this;
}

} //namespace WCDB
