//
//  sql_clause.cpp
//  alloy
//
//  Created by Alex Lee on 29/09/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#include "sql_clause.hpp"

namespace aldb {
SQLClause::SQLClause() {}
    
SQLClause::SQLClause(const SQLClause &other): _sql(other._sql), _values(other._values) {};
    
SQLClause::SQLClause(const std::string &sql) : _sql(sql) {}

SQLClause::SQLClause(const std::string &sql, const std::list<SQLValue> &values)
    : _sql(sql), _values(values.begin(), values.end()) {}

SQLClause &SQLClause::append(const std::string &sql, const std::list<SQLValue> &values) {
    _sql.append(sql);
    _values.insert(_values.end(), values.begin(), values.end());
    return *this;
}

SQLClause &SQLClause::append(const std::string &sql) {
    _sql.append(sql);
    return *this;
}

SQLClause &SQLClause::append(const SQLClause &clause) {
    _sql.append(clause._sql);
    _values.insert(_values.end(), clause._values.begin(), clause._values.end());
    return *this;
}

SQLClause &SQLClause::reset() {
    _sql.clear();
    _values.clear();
    return *this;
}

SQLClause &SQLClause::parenthesized() {
    _sql.insert(0, "(").append(")");
    return *this;
}

SQLClause &SQLClause::operator=(const SQLClause &o) {
    if (this != &o) {
        _sql = o._sql;
        _values.clear();
        _values.insert(_values.end(), o._values.begin(), o._values.end());
    }
    return *this;
}

bool SQLClause::empty() const {
    return _sql.empty();
}

const std::string &SQLClause::sql() const {
    return _sql;
}

const std::list<const SQLValue> &SQLClause::values() const {
    return _values;
}

}
