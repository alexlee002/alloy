//
//  ALDBColumnDefine.m
//  alloy
//
//  Created by Alex Lee on 16/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDBColumnDefine.h"
#import "utils.hpp"
#import "defines.hpp"
#import "ALSQLExpr.h"
#import "ALSQLValue.h"

ALDBColumnDefine::ALDBColumnDefine(const ALDBColumn &column, ALDBColumnType type)
    : _column(column),
      _type(type),
      _type_name(aldb::column_type_name((aldb::ColumnType)type)),
      _constraints(""),
      _auto_increment(false),
      _primary(false),
      _unique(false) {}

ALDBColumnDefine::ALDBColumnDefine(const ALDBColumn &column, const std::string &type_name)
    : _column(column),
      _type((ALDBColumnType)aldb::column_type_for_name(type_name)),
      _type_name(aldb::str_to_upper(type_name)),
      _constraints(""),
      _auto_increment(false),
      _primary(false),
      _unique(false) {}

ALDBColumnDefine::operator ALSQLClause() const {
    ALSQLClause clause(std::string(_column) + " " + _type_name);
    if (!_constraints.is_empty()) {
        clause.append(" ");
        clause.append(_constraints);
    }
    return clause;
}

ALDBColumnDefine &ALDBColumnDefine::as_primary(ALDBOrder order_term, ALDBConflictPolicy on_conflict,
                                               bool auto_increment) {
    _constraints.append(" PRIMARY KEY");
    _primary = true;

    if (order_term != ALDBOrderDefault) {
        _constraints.append(" ");
        _constraints.append(aldb::order_term((aldb::OrderBy) order_term));
    }

    if (on_conflict != ALDBConflictPolicyDefault) {
        _constraints.append(" ON CONFLICT ");
        _constraints.append(aldb::conflict_term((aldb::ConflictPolicy) on_conflict));
    }

    if (auto_increment) {
        _constraints.append(" AUTOINCREMENT");
        _auto_increment = true;
    }

    return *this;
}

ALDBColumnDefine &ALDBColumnDefine::as_unique(ALDBConflictPolicy on_conflict) {
    _constraints.append(" UNIQUE");

    if (on_conflict != ALDBConflictPolicyDefault) {
        _constraints.append(" ON CONFLICT ");
        _constraints.append(aldb::conflict_term((aldb::ConflictPolicy) on_conflict));
    }
    _unique = true;
    return *this;
}

ALDBColumnDefine &ALDBColumnDefine::not_null(ALDBConflictPolicy on_conflict) {
    _constraints.append(" NOT NULL");

    if (on_conflict != ALDBConflictPolicyDefault) {
        _constraints.append(" ON CONFLICT ");
        _constraints.append(aldb::conflict_term((aldb::ConflictPolicy) on_conflict));
    }
    return *this;
}

ALDBColumnDefine &ALDBColumnDefine::default_value(const ALSQLExpr &expr) {
    _constraints.append(" DEFAULT ");
    _constraints.append(ALSQLClause(expr));
    return *this;
}

ALDBColumnDefine &ALDBColumnDefine::default_value(const ALSQLValue &value) {
    _constraints.append(" DEFAULT " + std::string(aldb::SQLValue(value)));
    return *this;
}

ALDBColumnDefine &ALDBColumnDefine::default_value(ALDBDefaultTime time_value) {
    _constraints.append(" DEFAULT ");
    switch (time_value) {
        case ALDBDefaultTimeCurrentDateTime:
            _constraints.append("CURRENT_TIMESTAMP");
            break;
        case ALDBDefaultTimeCurrentDate:
            _constraints.append("CURRENT_DATE");
            break;
        case ALDBDefaultTimeCurrentTime:
            _constraints.append("CURRENT_TIME");
            break;

        default:
            break;
    }
    return *this;
}

ALDBColumnDefine &ALDBColumnDefine::collate(const std::string &name) {
    _constraints.append(" COLLATE " + name);
    return *this;
}

ALDBColumnDefine &ALDBColumnDefine::check(const ALSQLExpr &expr) {
    _constraints.append(" CHECK ");
    _constraints.append(ALSQLClause(expr));
    return *this;
}

const ALDBColumn &ALDBColumnDefine::column() const { return _column; }

ALDBColumnType ALDBColumnDefine::column_type() const { return _type; }

const std::string &ALDBColumnDefine::type_name() const { return _type_name; }

NSString *_Nonnull ALDBColumnDefine::typeName() { return @(_type_name.c_str()); }

bool ALDBColumnDefine::auto_increment() const { return _auto_increment; }

bool ALDBColumnDefine::is_primary() const { return _primary; }

bool ALDBColumnDefine::is_unique() const { return _unique; }
