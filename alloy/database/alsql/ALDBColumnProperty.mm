//
//  ALDBColumnProperty.m
//  alloy
//
//  Created by Alex Lee on 21/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDBColumnProperty.h"
#import "ALSQLValue.h"
#import "__ALModelMeta+ActiveRecord.h"
#import "__ALPropertyColumnBindings+private.h"

//ALDBColumnProperty::ALDBColumnProperty(const ALDBColumnProperty &o): ALDBColumn(o), _binding(o._binding) {}

ALDBColumnProperty::ALDBColumnProperty(): ALDBColumn("") {}

ALDBColumnProperty::ALDBColumnProperty(ALPropertyColumnBindings *propertyColumnBidings)
    : ALDBColumn(propertyColumnBidings.columnName), _binding(propertyColumnBidings) {}

//ALDBColumnProperty::ALDBColumnProperty(const std::string &columnName,
//                                       ALPropertyColumnBindings *propertyColumnBidings)
//    : ALDBColumn(columnName), _binding(propertyColumnBidings) {}

ALDBColumnProperty::ALDBColumnProperty(const ALDBColumn &column,
                                       ALPropertyColumnBindings *propertyColumnBidings)
    : ALDBColumn(column), _binding(propertyColumnBidings) {}

//ALDBColumnProperty ALDBColumnProperty::distinct() const {
//
//}

ALDBColumnProperty ALDBColumnProperty::in_table(NSString *tableName) const {
    return ALDBColumnProperty(ALDBColumn::in_table(tableName.UTF8String), _binding);
}

//ALDBColumnProperty ALDBColumnProperty::desc() const {
//}
//
//
//ALDBColumnProperty asc() const;

const std::string ALDBColumnProperty::name() const {
    return ALDBColumn::to_string();
}

id ALDBColumnProperty::column_binding() const {
    return _binding;
}

Class ALDBColumnProperty::binding_class() const {
    if (!_binding) {
        return Nil;
    }
    return (ALPropertyColumnBindings *)_binding->_cls;
}

// unary
ALSQLExpr ALDBColumnProperty::operator!() const {
    return !ALSQLExpr(*this);
}

ALSQLExpr ALDBColumnProperty::operator+() const {
    return +ALSQLExpr(*this);
}

ALSQLExpr ALDBColumnProperty::operator-() const {
    return -ALSQLExpr(*this);
}

ALSQLExpr ALDBColumnProperty::operator~() const {
    return ~ALSQLExpr(*this);
}

// binary
ALSQLExpr ALDBColumnProperty::operator||(const ALSQLExpr &r) const {  // or, not concat
    return ALSQLExpr(*this) || r;
}

ALSQLExpr ALDBColumnProperty::operator&&(const ALSQLExpr &r) const {
    return ALSQLExpr(*this) && r;
}

ALSQLExpr ALDBColumnProperty::operator*(const ALSQLExpr &r) const {
    return ALSQLExpr(*this) * r;
}

ALSQLExpr ALDBColumnProperty::operator/(const ALSQLExpr &r) const {
    return ALSQLExpr(*this) / r;
}

ALSQLExpr ALDBColumnProperty::operator%(const ALSQLExpr &r) const {
    return ALSQLExpr(*this) % r;
}

ALSQLExpr ALDBColumnProperty::operator+(const ALSQLExpr &r) const {
    return ALSQLExpr(*this) + r;
}

ALSQLExpr ALDBColumnProperty::operator-(const ALSQLExpr &r) const {
    return ALSQLExpr(*this) - r;
}

ALSQLExpr ALDBColumnProperty::operator<<(const ALSQLExpr &r) const {
    return ALSQLExpr(*this) << r;
}

ALSQLExpr ALDBColumnProperty::operator>>(const ALSQLExpr &r) const {
    return ALSQLExpr(*this) >> r;
}

ALSQLExpr ALDBColumnProperty::operator&(const ALSQLExpr &r) const {
    return ALSQLExpr(*this) & r;
}

ALSQLExpr ALDBColumnProperty::operator|(const ALSQLExpr &r) const {
    return ALSQLExpr(*this) | r;
}

ALSQLExpr ALDBColumnProperty::operator<(const ALSQLExpr &r) const {
    return ALSQLExpr(*this) < r;
}

ALSQLExpr ALDBColumnProperty::operator<=(const ALSQLExpr &r) const {
    return ALSQLExpr(*this) <= r;
}

ALSQLExpr ALDBColumnProperty::operator>(const ALSQLExpr &r) const {
    return ALSQLExpr(*this) > r;
}

ALSQLExpr ALDBColumnProperty::operator>=(const ALSQLExpr &r) const {
    return ALSQLExpr(*this) >= r;
}

ALSQLExpr ALDBColumnProperty::operator==(const ALSQLExpr &r) const {
    return ALSQLExpr(*this) == r;
}

ALSQLExpr ALDBColumnProperty::operator!=(const ALSQLExpr &r) const {
    return ALSQLExpr(*this) != r;
}

ALSQLExpr ALDBColumnProperty::in(const std::list<const ALSQLExpr> &expr_list) const {
    return ALSQLExpr(*this).in(expr_list);
}

ALSQLExpr ALDBColumnProperty::in(const std::string &table_name) const {
    return ALSQLExpr(*this).in(table_name);
}
//    ALSQLExpr in(const SelectStatement &stmt) const;
ALSQLExpr ALDBColumnProperty::not_in(const std::list<const ALSQLExpr> &expr_list) const {
    return ALSQLExpr(*this).not_in(expr_list);
}

ALSQLExpr ALDBColumnProperty::not_in(const std::string &table_name) const {
    return ALSQLExpr(*this).not_in(table_name);
}
//    ALSQLExpr not_in(const char *table_name) const;

ALSQLExpr ALDBColumnProperty::like(const ALSQLExpr &expr, const ALSQLExpr &escape) const {
    return ALSQLExpr(*this).like(expr, escape);
}

ALSQLExpr ALDBColumnProperty::not_like(const ALSQLExpr &expr, const ALSQLExpr &escape) const {
    return ALSQLExpr(*this).not_like(expr, escape);
}

ALSQLExpr ALDBColumnProperty::is_null() const {
    return ALSQLExpr(*this).is_null();
}

ALSQLExpr ALDBColumnProperty::not_null() const {
    return ALSQLExpr(*this).not_null();
}

ALSQLExpr ALDBColumnProperty::is(const ALSQLExpr &expr) const {
    return ALSQLExpr(*this).is(expr);
}

ALSQLExpr ALDBColumnProperty::is_not(const ALSQLExpr &expr) const {
    return ALSQLExpr(*this).is_not(expr);
}

ALSQLExpr ALDBColumnProperty::cast_as(const std::string &type_name) {
    return ALSQLExpr(*this).cast_as(type_name);
}

ALSQLExpr ALDBColumnProperty::cast_as(const ALDBColumnType type) {
    return ALSQLExpr(*this).cast_as(type);
}
//    static ALSQLExpr exists(const SelectStatement &stmt);
//    static ALSQLExpr not_exists(const SelectStatement &stmt);

// case (*this) when b then c else d end
ALSQLExpr ALDBColumnProperty::case_when(const std::list<const std::pair<const ALSQLExpr, const ALSQLExpr>> &when_then,
                                        const ALSQLExpr &else_value) {
    return ALSQLExpr(*this).case_when(when_then, else_value);
}

#pragma mark - sql functions
//@link: http://www.sqlite.org/lang_corefunc.html

ALSQLExpr ALDBColumnProperty::function(const std::string &name, bool distinct) {
    return ALSQLExpr(*this).function(name, distinct);
}

ALSQLExpr ALDBColumnProperty::concat(const ALSQLExpr &expr) const { // "abc"||"def"
    return ALSQLExpr(*this).concat(expr);
}

ALSQLExpr ALDBColumnProperty::abs() const {
    return ALSQLExpr(*this).abs();
}

ALSQLExpr ALDBColumnProperty::length() const {
    return ALSQLExpr(*this).length();
}

ALSQLExpr ALDBColumnProperty::lower() const {
    return ALSQLExpr(*this).lower();
}

ALSQLExpr ALDBColumnProperty::upper() const {
    return ALSQLExpr(*this).upper();
}

// expr.instr(str) => "INSTR(str, expr)"
ALSQLExpr ALDBColumnProperty::instr(const ALSQLExpr &str) const {
    return ALSQLExpr(*this).instr(str);
}

ALSQLExpr ALDBColumnProperty::substr(const ALSQLExpr &from) const {
    return ALSQLExpr(*this).substr(from);
}

ALSQLExpr ALDBColumnProperty::substr(const ALSQLExpr &from, const ALSQLExpr &len) const {
    return ALSQLExpr(*this).substr(from, len);
}

ALSQLExpr ALDBColumnProperty::replace(const ALSQLExpr &find, const ALSQLExpr &replacement) const {
    return ALSQLExpr(*this).replace(find, replacement);
}

ALSQLExpr ALDBColumnProperty::ltrim() const {
    return ALSQLExpr(*this).ltrim();
}

ALSQLExpr ALDBColumnProperty::ltrim(const ALSQLExpr &trim_str) const {
    return ALSQLExpr(*this).ltrim(trim_str);
}

ALSQLExpr ALDBColumnProperty::rtrim() const {
    return ALSQLExpr(*this).rtrim();
}

ALSQLExpr ALDBColumnProperty::rtrim(const ALSQLExpr &trim_str) const {
    return ALSQLExpr(*this).rtrim(trim_str);
}

ALSQLExpr ALDBColumnProperty::trim() const {
    return ALSQLExpr(*this).trim();
}

ALSQLExpr ALDBColumnProperty::trim(const ALSQLExpr &trim_str) const {
    return ALSQLExpr(*this).trim(trim_str);
}

ALSQLExpr ALDBColumnProperty::avg(bool distinct) const {
    return ALSQLExpr(*this).avg(distinct);
}

ALSQLExpr ALDBColumnProperty::count(bool distinct) const {
    return ALSQLExpr(*this).count(distinct);
}

ALSQLExpr ALDBColumnProperty::group_concat(bool distinct) const {
    return ALSQLExpr(*this).group_concat(distinct);
}

ALSQLExpr ALDBColumnProperty::group_concat(const ALSQLExpr &seperator, bool distinct) const {
    return ALSQLExpr(*this).group_concat(seperator, distinct);
}

ALSQLExpr ALDBColumnProperty::max(bool distinct) const {
    return ALSQLExpr(*this).max(distinct);
}

ALSQLExpr ALDBColumnProperty::min(bool distinct) const {
    return ALSQLExpr(*this).min(distinct);
}

ALSQLExpr ALDBColumnProperty::sum(bool distinct) const {
    return ALSQLExpr(*this).sum(distinct);
}

ALSQLExpr ALDBColumnProperty::total(bool distinct) const {
    return ALSQLExpr(*this).total(distinct);
}
