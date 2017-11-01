//
//  ALDBExpr.m
//  alloy
//
//  Created by Alex Lee on 07/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDBExpr.h"
#import "NSObject+SQLValue.h"
#import "ALDBProperty.h"
#import "ALDBResultColumn.h"
#import "sql_select.hpp"

__ALDB_PROPERTY_BASE_IMP(ALDBExpr);

ALDBExpr::ALDBExpr() : aldb::Expr(), __ALDB_PROPERTY_BASE_CTOR(nil, nil) {
}

ALDBExpr::ALDBExpr(NSString *column, id value)
    : aldb::Expr(column.UTF8String, [value al_SQLValue]), __ALDB_PROPERTY_BASE_CTOR(nil, nil) {
}

//template <typename T>
//ALDBExpr::ALDBExpr(const T &value,
//                   typename std::enable_if<std::is_arithmetic<T>::value || std::is_enum<T>::value>::type *)
//    : aldb::Expr(value), __ALDB_PROPERTY_BASE_CTOR(nil, nil) {
//}

ALDBExpr::ALDBExpr(const char *value) :aldb::Expr(value), __ALDB_PROPERTY_BASE_CTOR(nil, nil) {
}

ALDBExpr::ALDBExpr(long value) : aldb::Expr(value), __ALDB_PROPERTY_BASE_CTOR(nil, nil) {
}

ALDBExpr::ALDBExpr(const ALDBProperty &column) : aldb::Expr(column), __ALDB_PROPERTY_BASE_CTOR1(column) {
}

ALDBExpr::ALDBExpr(id value) : aldb::Expr([value al_SQLValue]), __ALDB_PROPERTY_BASE_CTOR(nil, nil) {
}

ALDBExpr::ALDBExpr(const aldb::Expr &expr) : aldb::Expr(expr), __ALDB_PROPERTY_BASE_CTOR(nil, nil) {
}

ALDBExpr::ALDBExpr(const aldb::Expr &expr, /*ALDBProperty(*/ Class cls, ALDBColumnBinding *binding /*)*/)
    : aldb::Expr(expr), __ALDB_PROPERTY_BASE_CTOR(cls, binding) {
}

ALDBResultColumn ALDBExpr::as(const ALDBProperty &property) {
    return ALDBResultColumn(*this).as(property);
}

ALDBResultColumnList ALDBExpr::distinct() const {
    return ALDBResultColumnList(*this).distinct();
}

ALDBOrderBy ALDBExpr::order(ALDBOrder order) {
    return ALDBOrderBy(*this, (aldb::OrderBy) order);
}

ALDBExpr &ALDBExpr::operator=(const ALDBExpr &other) {
    if (this != &other) {
        aldb::Expr::operator=(other);
        _cls           = other.bindingClass();
        _columnBinding = other.columnBinding();
    }
    return *this;
}

#pragma mark -
// unary
ALDBExpr ALDBExpr::operator!() const {
    return ALDBExpr(Expr::operator!(), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::operator+() const {
    return ALDBExpr(Expr::operator+(), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::operator-() const {
    return ALDBExpr(Expr::operator-(), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::operator~() const {
    return ALDBExpr(Expr::operator~(), __ALDB_CAST_PROPERTY(*this));
}

// binary
ALDBExpr ALDBExpr::operator||(const ALDBExpr &r) const {  // or, not concat
    return ALDBExpr(Expr::operator||(r), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::operator&&(const ALDBExpr &r) const {
    return ALDBExpr(Expr::operator&&(r), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::operator*(const ALDBExpr &r) const {
    return ALDBExpr(Expr::operator*(r), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::operator/(const ALDBExpr &r) const {
    return ALDBExpr(Expr::operator/(r), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::operator%(const ALDBExpr &r) const {
    return ALDBExpr(Expr::operator%(r), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::operator+(const ALDBExpr &r) const {
    return ALDBExpr(Expr::operator+(r), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::operator-(const ALDBExpr &r) const {
    return ALDBExpr(Expr::operator-(r), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::operator<<(const ALDBExpr &r) const {
    return ALDBExpr(Expr::operator<<(r), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::operator>>(const ALDBExpr &r) const {
    return ALDBExpr(Expr::operator>>(r), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::operator&(const ALDBExpr &r) const {
    return ALDBExpr(Expr::operator&(r), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::operator|(const ALDBExpr &r) const {
    return ALDBExpr(Expr::operator|(r), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::operator<(const ALDBExpr &r) const {
    return ALDBExpr(Expr::operator<(r), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::operator<=(const ALDBExpr &r) const {
    return ALDBExpr(Expr::operator<=(r), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::operator>(const ALDBExpr &r) const {
    return ALDBExpr(Expr::operator>(r), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::operator>=(const ALDBExpr &r) const {
    return ALDBExpr(Expr::operator>=(r), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::operator==(const ALDBExpr &r) const {
    return ALDBExpr(Expr::operator==(r), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::operator!=(const ALDBExpr &r) const {
    return ALDBExpr(Expr::operator!=(r), __ALDB_CAST_PROPERTY(*this));
}


ALDBExpr ALDBExpr::in(const std::list<const ALDBExpr> &expr_list) const {
    return ALDBExpr(Expr::in(expr_list), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::in(const std::string &table_name) const {
    return ALDBExpr(Expr::in(table_name), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::in(NSString *tableName) const {
    return ALDBExpr(Expr::in(tableName.UTF8String), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::in(const aldb::SQLSelect &stmt) const {
    return ALDBExpr(Expr::in(stmt), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::in(NSArray *values) const {
    std::list<const ALDBExpr> list;
    for (id val in values) {
        list.push_back(ALDBExpr(val));
    }
    return ALDBExpr(Expr::in(list), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::not_in(const std::list<const ALDBExpr> &expr_list) const {
    return ALDBExpr(Expr::not_in(expr_list), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::not_in(const std::string &table_name) const {
    return ALDBExpr(Expr::not_in(table_name), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::not_in(NSString *tableName) const {
    return ALDBExpr(Expr::not_in(tableName.UTF8String), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::not_in(const aldb::SQLSelect &stmt) const {
    return ALDBExpr(Expr::not_in(stmt), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::not_in(NSArray *values) const {
    std::list<const ALDBExpr> list;
    for (id val in values) {
        list.push_back(ALDBExpr(val));
    }
    return ALDBExpr(Expr::not_in(list), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::between(const ALDBExpr &left, const ALDBExpr &right) const {
    return ALDBExpr(Expr::between(left, right), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::not_between(const ALDBExpr &left, const ALDBExpr &right) const {
    return ALDBExpr(Expr::not_between(left, right), __ALDB_CAST_PROPERTY(*this));
}


ALDBExpr ALDBExpr::like(const ALDBExpr &expr) const {
    return ALDBExpr(Expr::like(expr), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::not_like(const ALDBExpr &expr) const {
    return ALDBExpr(Expr::not_like(expr), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::like(const ALDBExpr &expr, const ALDBExpr &escape) const {
    return ALDBExpr(Expr::like(expr, escape), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::not_like(const ALDBExpr &expr, const ALDBExpr &escape) const {
    return ALDBExpr(Expr::not_like(expr, escape), __ALDB_CAST_PROPERTY(*this));
}


ALDBExpr ALDBExpr::glob(const ALDBExpr &expr) const {
    return ALDBExpr(Expr::glob(expr), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::not_glob(const ALDBExpr &expr) const {
    return ALDBExpr(Expr::not_glob(expr), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::glob(const ALDBExpr &expr, const ALDBExpr &escape) const {
    return ALDBExpr(Expr::glob(expr, escape), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::not_glob(const ALDBExpr &expr, const ALDBExpr &escape) const {
    return ALDBExpr(Expr::not_glob(expr, escape), __ALDB_CAST_PROPERTY(*this));
}


ALDBExpr ALDBExpr::match(const ALDBExpr &expr) const {
    return ALDBExpr(Expr::match(expr), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::not_match(const ALDBExpr &expr) const {
    return ALDBExpr(Expr::not_match(expr), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::match(const ALDBExpr &expr, const ALDBExpr &escape) const {
    return ALDBExpr(Expr::match(expr, escape), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::not_match(const ALDBExpr &expr, const ALDBExpr &escape) const {
    return ALDBExpr(Expr::not_match(expr, escape), __ALDB_CAST_PROPERTY(*this));
}


ALDBExpr ALDBExpr::regexp(const ALDBExpr &expr) const {
    return ALDBExpr(Expr::regexp(expr), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::not_regexp(const ALDBExpr &expr) const {
    return ALDBExpr(Expr::not_regexp(expr), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::regexp(const ALDBExpr &expr, const ALDBExpr &escape) const {
    return ALDBExpr(Expr::regexp(expr, escape), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::not_regexp(const ALDBExpr &expr, const ALDBExpr &escape) const {
    return ALDBExpr(Expr::not_regexp(expr, escape), __ALDB_CAST_PROPERTY(*this));
}


ALDBExpr ALDBExpr::is_null() const {
    return ALDBExpr(Expr::is_null(), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::not_null() const {
    return ALDBExpr(Expr::not_null(), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::is(const ALDBExpr &expr) const {
    return ALDBExpr(Expr::is(expr), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::is_not(const ALDBExpr &expr) const {
    return ALDBExpr(Expr::is_not(expr), __ALDB_CAST_PROPERTY(*this));
}


ALDBExpr ALDBExpr::cast_as(const std::string &type_name) const {
    return ALDBExpr(Expr::cast_as(type_name), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::cast_as(const aldb::ColumnType type) const {
    return ALDBExpr(Expr::cast_as(type), __ALDB_CAST_PROPERTY(*this));
}


// case (*this) when b then c else d end
ALDBExpr ALDBExpr::case_when(const std::list<const std::pair<const ALDBExpr, const ALDBExpr>> &when_then) {
    return ALDBExpr(Expr::case_when(when_then), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::case_when(const std::list<const std::pair<const ALDBExpr, const ALDBExpr>> &when_then,
                             const ALDBExpr &else_value) {
    return ALDBExpr(Expr::case_when(when_then, else_value), __ALDB_CAST_PROPERTY(*this));
}

#pragma mark - functions
ALDBExpr ALDBExpr::function(const std::string &fun_name, const std::list<const ALDBExpr> &args, bool distinct) {
    return ALDBExpr(Expr::function(fun_name, args, distinct));
}

ALDBExpr ALDBExpr::function(const std::string &name, bool distinct) const {
    return ALDBExpr(Expr::function(name), __ALDB_CAST_PROPERTY(*this));
}
//operation: "abc"||"def"
ALDBExpr ALDBExpr::concat(const ALDBExpr &expr) const {
    return ALDBExpr(Expr::concat(expr), __ALDB_CAST_PROPERTY(*this));
}

//aggregate functions
ALDBExpr ALDBExpr::avg(bool distinct) const {
    return ALDBExpr(Expr::avg(distinct), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::count(bool distinct) const {
    return ALDBExpr(Expr::count(distinct), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::group_concat(bool distinct) const {
    return ALDBExpr(Expr::group_concat(distinct), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::group_concat(const ALDBExpr &seperator, bool distinct) const {
    return ALDBExpr(Expr::group_concat(seperator, distinct), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::max(bool distinct) const {
    return ALDBExpr(Expr::max(distinct), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::min(bool distinct) const {
    return ALDBExpr(Expr::min(distinct), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::sum(bool distinct) const {
    return ALDBExpr(Expr::sum(distinct), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::total(bool distinct) const {
    return ALDBExpr(Expr::total(distinct), __ALDB_CAST_PROPERTY(*this));
}

//core functions
ALDBExpr ALDBExpr::abs() const {
    return ALDBExpr(Expr::abs(), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::length() const {
    return ALDBExpr(Expr::length(), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::lower() const {
    return ALDBExpr(Expr::lower(), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::upper() const {
    return ALDBExpr(Expr::upper(), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::round(bool distinct) const {
    return ALDBExpr(Expr::round(distinct), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::hex(bool distinct) const {
    return ALDBExpr(Expr::hex(distinct), __ALDB_CAST_PROPERTY(*this));
}

// ALDBExpr.instr(str) => "INSTR(str, ALDBExpr)"
ALDBExpr ALDBExpr::instr(const ALDBExpr &str) const {
    return ALDBExpr(Expr::instr(str), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::substr(const ALDBExpr &from) const {
    return ALDBExpr(Expr::substr(from), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::substr(const ALDBExpr &from, const ALDBExpr &len) const {
    return ALDBExpr(Expr::substr(from, len), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::replace(const ALDBExpr &find, const ALDBExpr &replacement) const {
    return ALDBExpr(Expr::replace(find, replacement), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::ltrim() const {
    return ALDBExpr(Expr::ltrim(), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::ltrim(const ALDBExpr &trim_str) const {
    return ALDBExpr(Expr::ltrim(trim_str), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::rtrim() const {
    return ALDBExpr(Expr::rtrim(), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::rtrim(const ALDBExpr &trim_str) const {
    return ALDBExpr(Expr::rtrim(trim_str), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::trim() const {
    return ALDBExpr(Expr::trim(), __ALDB_CAST_PROPERTY(*this));
}

ALDBExpr ALDBExpr::trim(const ALDBExpr &trim_str) const {
    return ALDBExpr(Expr::trim(trim_str), __ALDB_CAST_PROPERTY(*this));
}

