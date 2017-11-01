//
//  column_def.cpp
//  alloy
//
//  Created by Alex Lee on 30/09/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#include "column_def.hpp"
#include "column.hpp"
#include "expr.hpp"
#include "sql_value.hpp"

namespace aldb {
ColumnDef::ColumnDef(const Column &column, ColumnType type) :
        SQLClause(column.name() + " " + aldb::column_type_name(type)),
        _primary(false),
        _autoincrement(false),
        _unique(false) {
}

ColumnDef &ColumnDef::as_primary(OrderBy order, ConflictPolicy conflict, bool auto_increment) {
    _primary = true;
    SQLClause::append(" PRIMARY KEY");
    if (order != OrderBy::DEFAULT) {
        SQLClause::append(" ").append(aldb::order_term(order));
    }

    if (conflict != ConflictPolicy::DEFAULT) {
        SQLClause::append(" ON CONFLICT ").append(aldb::conflict_term(conflict));
    }

    if (auto_increment) {
        _autoincrement = true;
        SQLClause::append(" AUTOINCREMENT");
    }

    return *this;
}

ColumnDef &ColumnDef::not_null(ConflictPolicy conflict) {
    SQLClause::append(" NOT NULL");
    if (conflict != ConflictPolicy::DEFAULT) {
        SQLClause::append(" ON CONFLICT ").append(aldb::conflict_term(conflict));
    }
    return *this;
}

ColumnDef &ColumnDef::as_unique(ConflictPolicy conflict) {
    _unique = true;
    SQLClause::append(" UNIQUE");
    if (conflict != ConflictPolicy::DEFAULT) {
        SQLClause::append(" ON CONFLICT ").append(aldb::conflict_term(conflict));
    }
    return *this;
}

ColumnDef &ColumnDef::check(const Expr &expr) {
    SQLClause::append(" CHECK (").append(expr).append(")");
    return *this;
}

ColumnDef &ColumnDef::default_value(const SQLValue &value) {
    SQLClause::append(" DEFAULT ").append(std::string(value));
    return *this;
}

ColumnDef &ColumnDef::default_value(const Expr &value) {
    SQLClause::append(" DEFAULT (").append(value).append(")");
    return *this;
}

ColumnDef &ColumnDef::default_value(const std::nullptr_t &value) {
    SQLClause::append(" DEFAULT NULL");
    return *this;
}

ColumnDef &ColumnDef::default_value(DefaultTimeValue time) {
    if (time != DefaultTimeValue::NOT_SET) {
        SQLClause::append(" DEFAULT " + aldb::literal_default_time_value(time));
    }
    return *this;
}

ColumnDef &ColumnDef::collate(const std::string &name) {
    SQLClause::append(" COLLATE " + name);
    return *this;
}

bool ColumnDef::is_primary() const { return _primary; }
bool ColumnDef::is_autoincrement() const { return _autoincrement; };
bool ColumnDef::is_unique() const { return _unique; }
}
