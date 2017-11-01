//
//  sql_vacuum.cpp
//  alloy
//
//  Created by Alex Lee on 02/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//
//  Fork from WCDB, github: https://github.com/tencent/wcdb
//
#include "sql_vacuum.hpp"

namespace aldb {

SQLVacuum &SQLVacuum::vacuum(const std::string &schemaName) {
    SQLClause::append("VACUUM " + schemaName);
    return *this;
}

} //namespace WCDB
