
    
//
//  column.cpp
//  alloy
//
//  Created by Alex Lee on 30/09/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#include "column.hpp"

namespace aldb {
const Column Column::ANY("*");
const Column Column::ROWID("rowid");

Column::Column()
    : SQLClause() {}

Column::Column(const char *name)
    : SQLClause(name) {}

Column::Column(const std::string &name)
    : SQLClause(name) {}

const std::string &Column::name() const {
    return SQLClause::sql();
}

Column::operator const std::string &() const {
    return name();
}

Column Column::in_table(const std::string &table) const {
    return Column(table + "." + sql());
}

Column::operator std::list<Column>() const {
    return {*this};
}

bool Column::operator==(const Column &column) const {
    return sql() == column.sql();
}

}
