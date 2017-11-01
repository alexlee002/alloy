//
//  sql_update.cpp
//  alloy
//
//  Created by Alex Lee on 30/09/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#include "sql_update.hpp"
#include "expr.hpp"
#include "qualified_table_name.hpp"
#include "column.hpp"

namespace aldb {
#pragma mark - UpdateColumns
UpdateColumns::UpdateColumns(const Column &column)
    : SQLClause(column.name()) {}

UpdateColumns::operator aldb::Column() const {
    return aldb::Column(SQLClause::sql());
}

#pragma mark - SQLUpdate
SQLUpdate &SQLUpdate::update(const QualifiedTableName &table, ConflictPolicy conflict) {
    SQLClause::append("UPDATE ");
    if (conflict != ConflictPolicy::DEFAULT) {
        SQLClause::append("OR ").append(aldb::conflict_term(conflict)).append(" ");
    }

    SQLClause::append(table);
    return *this;
}

SQLUpdate &SQLUpdate::where(const Expr &where) {
    if (!where.empty()) {
        SQLClause::append(" WHERE ").append(where);
    }
    return *this;
}

SQLUpdate &SQLUpdate::limit(const Expr &offset, const Expr &limit) {
    if (!offset.empty()) {
        SQLClause::append(" LIMIT ").append(offset);
        if (!limit.empty()) {
            SQLClause::append(", ").append(limit);
        }
    }
    return *this;
}

SQLUpdate &SQLUpdate::limit(const Expr &limit) {
    if (!limit.empty()) {
        SQLClause::append(" LIMIT ").append(limit);
    }
    return *this;
}

SQLUpdate &SQLUpdate::offset(const Expr &offset) {
    if (!offset.empty()) {
        SQLClause::append(" OFFSET ").append(offset);
    }
    return *this;
}
}
