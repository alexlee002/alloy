//
//  sql_detach.cpp
//  alloy
//
//  Created by Alex Lee on 02/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//
//  Fork from WCDB, github: https://github.com/tencent/wcdb
//
#include "expr.hpp"
#include "sql_detach.hpp"

namespace aldb {

SQLDetach &SQLDetach::detach(const std::string &schema) {
    SQLClause::append("DETACH " + schema);
    return *this;
}

} //namespace WCDB
