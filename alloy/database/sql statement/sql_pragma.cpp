//
//  sql_pragma.cpp
//  alloy
//
//  Created by Alex Lee on 01/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#include "sql_pragma.hpp"
#include "pragma.hpp"
#include "sql_value.hpp"

namespace aldb {
SQLPragma &SQLPragma::pragma(const Pragma &pragma) {
    SQLClause::append("PRAGMA " + pragma.name());
    return *this;
}

SQLPragma &SQLPragma::pragma(const Pragma &pragma, const SQLValue &value) {
    SQLClause::append("PRAGMA " + pragma.name() + " = " + std::string(value));
    return *this;
}
}
