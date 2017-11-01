//
//  qualified_table_name.cpp
//  alloy
//
//  Created by Alex Lee on 01/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#include "qualified_table_name.hpp"

namespace aldb {
QualifiedTableName::QualifiedTableName(const std::string &table_name) : SQLClause(table_name) {
}

QualifiedTableName::QualifiedTableName(const char *table_name) : SQLClause(table_name) {
}

QualifiedTableName &QualifiedTableName::indexed_by(const std::string &index_name) {
    SQLClause::append(" INDEXED BY " + index_name);
    return *this;
}

QualifiedTableName &QualifiedTableName::not_indexed() {
    SQLClause::append(" NOT INDEXED");
    return *this;
}
}
