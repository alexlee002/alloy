//
//  table_constraint.cpp
//  alloy
//
//  Created by Alex Lee on 30/09/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#include "table_constraint.hpp"
#include "column_index.hpp"
#include "expr.hpp"

namespace aldb {
TableConstraint::TableConstraint()
    : SQLClause() {}

TableConstraint::TableConstraint(const std::string &name)
    : SQLClause("CONSTRAINT " + name) {}

TableConstraint &TableConstraint::primary_key(const std::list<const IndexColumn> &columns, ConflictPolicy conflict) {
    SQLClause::append(" PRIMARY KEY (").append(SQLClause::combine<SQLClause>(columns, ", ")).append(")");
    on_conflict(conflict);
    return *this;
}

TableConstraint &TableConstraint::unique(const std::list<const IndexColumn> &columns, ConflictPolicy conflict) {
    SQLClause::append(" UNIQUE (").append(SQLClause::combine<SQLClause>(columns, ", ")).append(")");
    on_conflict(conflict);
    return *this;
}

TableConstraint &TableConstraint::check(const Expr &expr) {
    SQLClause::append(" CHECK (").append(expr).append(")");
    return *this;
}

void TableConstraint::on_conflict(ConflictPolicy conflict) {
    if (conflict != ConflictPolicy::DEFAULT) {
        SQLClause::append(" ON CONFLICT ").append(aldb::conflict_term(conflict));
    }
}

}

