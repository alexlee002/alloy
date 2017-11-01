//
//  sql_savepoint.cpp
//  alloy
//
//  Created by Alex Lee on 02/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#include "sql_savepoint.hpp"

namespace aldb {
SQLSavePoint &SQLSavePoint::savepoint(const std::string &name) {
    SQLClause::reset().append("SAVEPOINT " + name);
    return *this;
}

SQLSavePoint &SQLSavePoint::release(const std::string &name) {
    SQLClause::reset().append("RELEASE SAVEPOINT " + name);
    return *this;
}

SQLSavePoint &SQLSavePoint::rollback(const std::string &name) {
    SQLClause::reset().append("ROLLBACK TO SAVEPOINT " + name);
    return *this;
}
}
