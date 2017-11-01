//
//  sql_reindex.cpp
//  alloy
//
//  Created by Alex Lee on 01/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#include "sql_reindex.hpp"

namespace aldb {
SQLReindex &SQLReindex::reindex(const std::string &name) {
    SQLClause::append("REINDEX " + name);
    return *this;
}
}
