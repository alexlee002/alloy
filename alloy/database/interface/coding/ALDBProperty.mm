//
//  ALDBProperty.m
//  alloy
//
//  Created by Alex Lee on 07/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDBProperty.h"
#import "ALDBExpr.h"
#import "ALDBResultColumn.h"

#pragma mark - ALDBProperty
__ALDB_PROPERTY_BASE_IMP(ALDBProperty);

ALDBProperty::ALDBProperty(const char *name) : aldb::Column(name), __ALDB_PROPERTY_BASE_CTOR(nil, nil) {
}

ALDBProperty::ALDBProperty(NSString *name) : aldb::Column(name.UTF8String), __ALDB_PROPERTY_BASE_CTOR(nil, nil) {
}

ALDBProperty::ALDBProperty(const aldb::Column &column) : aldb::Column(column), __ALDB_PROPERTY_BASE_CTOR(nil, nil) {
}

ALDBProperty::ALDBProperty(ALDBColumnBinding *binding)
    : aldb::Column(binding.columnName.UTF8String), __ALDB_PROPERTY_BASE_CTOR(binding.modelClass, binding) {
}

ALDBProperty::ALDBProperty(const char *name, Class modelCls, ALDBColumnBinding *columnBinding)
    : aldb::Column(name), __ALDB_PROPERTY_BASE_CTOR(modelCls, columnBinding) {
}

ALDBProperty::ALDBProperty(const aldb::Column &column, Class modelCls, ALDBColumnBinding *columnBinding)
    : aldb::Column(column), __ALDB_PROPERTY_BASE_CTOR(modelCls, columnBinding) {
}

ALDBResultColumnList ALDBProperty::distinct() const {
    return ALDBResultColumnList(*this).distinct();
}

ALDBProperty ALDBProperty::inTable(NSString *table) const {
    return ALDBProperty(aldb::Column::in_table(table.UTF8String).name(), _cls, _columnBinding);
}

ALDBOrderBy ALDBProperty::order(ALDBOrder order) const {
    return ALDBOrderBy(*this, (aldb::OrderBy) order);
}

ALDBIndex ALDBProperty::index(ALDBOrder order) const {
    return ALDBIndex(*this, aldb::BinaryCollate, (aldb::OrderBy) order);
}


#pragma mark - sql opetations
//@link: http://www.sqlite.org/lang_expr.html
// unary
ALDBExpr ALDBProperty::operator!() const {
    return !ALDBExpr(*this);
}

ALDBExpr ALDBProperty::operator+() const {
    return +ALDBExpr(*this);
}

ALDBExpr ALDBProperty::operator-() const {
    return -ALDBExpr(*this);
}

ALDBExpr ALDBProperty::operator~() const {
    return ~ALDBExpr(*this);
}


// binary
ALDBExpr ALDBProperty::operator||(const ALDBExpr &r) const {  // or, not concat
    return ALDBExpr(*this) || r;
}

ALDBExpr ALDBProperty::operator&&(const ALDBExpr &r) const {
    return ALDBExpr(*this) && r;
}

ALDBExpr ALDBProperty::operator*(const ALDBExpr &r) const {
    return ALDBExpr(*this) * r;
}

ALDBExpr ALDBProperty::operator/(const ALDBExpr &r) const {
    return ALDBExpr(*this) / r;
}

ALDBExpr ALDBProperty::operator%(const ALDBExpr &r) const {
    return ALDBExpr(*this) % r;
}

ALDBExpr ALDBProperty::operator+(const ALDBExpr &r) const {
    return ALDBExpr(*this) + r;
}

ALDBExpr ALDBProperty::operator-(const ALDBExpr &r) const {
    return ALDBExpr(*this) - r;
}

ALDBExpr ALDBProperty::operator<<(const ALDBExpr &r) const {
    return ALDBExpr(*this) << r;
}

ALDBExpr ALDBProperty::operator>>(const ALDBExpr &r) const {
    return ALDBExpr(*this) >> r;
}
ALDBExpr ALDBProperty::operator&(const ALDBExpr &r) const {
    return ALDBExpr(*this) & r;
}

ALDBExpr ALDBProperty::operator|(const ALDBExpr &r) const {
    return ALDBExpr(*this) | r;
}

ALDBExpr ALDBProperty::operator<(const ALDBExpr &r) const {
    return ALDBExpr(*this) < r;
}

ALDBExpr ALDBProperty::operator<=(const ALDBExpr &r) const {
    return ALDBExpr(*this) <= r;
}

ALDBExpr ALDBProperty::operator>(const ALDBExpr &r) const {
    return ALDBExpr(*this) > r;
}

ALDBExpr ALDBProperty::operator>=(const ALDBExpr &r) const {
    return ALDBExpr(*this) >= r;
}

ALDBExpr ALDBProperty::operator==(const ALDBExpr &r) const {
    return ALDBExpr(*this) == r;
}

ALDBExpr ALDBProperty::operator!=(const ALDBExpr &r) const {
    return ALDBExpr(*this) != r;
}

ALDBExpr ALDBProperty::in(const std::list<const ALDBExpr> &expr_list) const {
    return ALDBExpr(*this).in(expr_list);
}

ALDBExpr ALDBProperty::in(const std::string &table_name) const {
    return ALDBExpr(*this).in(table_name);
}

ALDBExpr ALDBProperty::in(NSString *table_name) const {
    return ALDBExpr(*this).in(table_name);
}

ALDBExpr ALDBProperty::in(const aldb::SQLSelect &stmt) const {
    return ALDBExpr(*this).in(stmt);
}

ALDBExpr ALDBProperty::in(NSArray *values) const {
    return ALDBExpr(*this).in(values);
}

ALDBExpr ALDBProperty::not_in(const std::list<const ALDBExpr> &expr_list) const {
    return ALDBExpr(*this).not_in(expr_list);
}

ALDBExpr ALDBProperty::not_in(const std::string &table_name) const {
    return ALDBExpr(*this).not_in(table_name);
}

ALDBExpr ALDBProperty::not_in(NSString *table_name) const {
    return ALDBExpr(*this).not_in(table_name);
}

ALDBExpr ALDBProperty::not_in(const aldb::SQLSelect &stmt) const {
    return ALDBExpr(*this).not_in(stmt);
}

ALDBExpr ALDBProperty::not_in(NSArray *values) const {
    return ALDBExpr(*this).not_in(values);
}

ALDBExpr ALDBProperty::between(const ALDBExpr &left, const ALDBExpr &right) const {
    return ALDBExpr(*this).between(left, right);
}

ALDBExpr ALDBProperty::not_between(const ALDBExpr &left, const ALDBExpr &right) const {
    return ALDBExpr(*this).not_between(left, right);
}


ALDBExpr ALDBProperty::like(const ALDBExpr &expr) const {
    return ALDBExpr(*this).like(expr);
}

ALDBExpr ALDBProperty::not_like(const ALDBExpr &expr) const {
    return ALDBExpr(*this).not_like(expr);
}

ALDBExpr ALDBProperty::like(const ALDBExpr &expr, const ALDBExpr &escape) const {
    return ALDBExpr(*this).like(expr, escape);
}

ALDBExpr ALDBProperty::not_like(const ALDBExpr &expr, const ALDBExpr &escape) const {
    return ALDBExpr(*this).not_like(expr, escape);
}


ALDBExpr ALDBProperty::glob(const ALDBExpr &expr) const {
    return ALDBExpr(*this).glob(expr);
}

ALDBExpr ALDBProperty::not_glob(const ALDBExpr &expr) const {
    return ALDBExpr(*this).not_glob(expr);
}

ALDBExpr ALDBProperty::glob(const ALDBExpr &expr, const ALDBExpr &escape) const {
    return ALDBExpr(*this).glob(expr, escape);
}

ALDBExpr ALDBProperty::not_glob(const ALDBExpr &expr, const ALDBExpr &escape) const {
    return ALDBExpr(*this).not_glob(expr, escape);
}


ALDBExpr ALDBProperty::match(const ALDBExpr &expr) const {
    return ALDBExpr(*this).match(expr);
}

ALDBExpr ALDBProperty::not_match(const ALDBExpr &expr) const {
    return ALDBExpr(*this).not_match(expr);
}

ALDBExpr ALDBProperty::match(const ALDBExpr &expr, const ALDBExpr &escape) const {
    return ALDBExpr(*this).match(expr, escape);
}

ALDBExpr ALDBProperty::not_match(const ALDBExpr &expr, const ALDBExpr &escape) const {
    return ALDBExpr(*this).not_match(expr, escape);
}


ALDBExpr ALDBProperty::regexp(const ALDBExpr &expr) const {
    return ALDBExpr(*this).regexp(expr);
}

ALDBExpr ALDBProperty::not_regexp(const ALDBExpr &expr) const {
    return ALDBExpr(*this).not_regexp(expr);
}

ALDBExpr ALDBProperty::regexp(const ALDBExpr &expr, const ALDBExpr &escape) const {
    return ALDBExpr(*this).regexp(expr, escape);
}

ALDBExpr ALDBProperty::not_regexp(const ALDBExpr &expr, const ALDBExpr &escape) const {
    return ALDBExpr(*this).not_regexp(expr, escape);
}


ALDBExpr ALDBProperty::is_null() const {
    return ALDBExpr(*this).is_null();
}

ALDBExpr ALDBProperty::not_null() const {
    return ALDBExpr(*this).not_null();
}

ALDBExpr ALDBProperty::is(const ALDBExpr &expr) const {
    return ALDBExpr(*this).is(expr);
}

ALDBExpr ALDBProperty::is_not(const ALDBExpr &expr) const {
    return ALDBExpr(*this).is_not(expr);
}


ALDBExpr ALDBProperty::cast_as(const std::string &type_name) const {
    return ALDBExpr(*this).cast_as(type_name);
}

ALDBExpr ALDBProperty::cast_as(const aldb::ColumnType type) const {
    return ALDBExpr(*this).cast_as(type);
}


// case (*this) when b then c else d end
ALDBExpr ALDBProperty::case_when(const std::list<const std::pair<const ALDBExpr, const ALDBExpr>> &when_then) {
    return ALDBExpr(*this).case_when(when_then);
}

ALDBExpr ALDBProperty::case_when(const std::list<const std::pair<const ALDBExpr, const ALDBExpr>> &when_then,
                                 const ALDBExpr &else_value) {
    return ALDBExpr(*this).case_when(when_then, else_value);
}

#pragma mark - sql functions

ALDBExpr ALDBProperty::function(const std::string &name, bool distinct) const {
    return ALDBExpr(*this).function(name, distinct);
}
//operation: "abc"||"def"
ALDBExpr ALDBProperty::concat(const ALDBExpr &expr) const {
    return ALDBExpr(*this).concat(expr);
}

//aggregate functions
ALDBExpr ALDBProperty::avg(bool distinct) const {
    return ALDBExpr(*this).avg(distinct);
}

ALDBExpr ALDBProperty::count(bool distinct) const {
    return ALDBExpr(*this).count(distinct);
}

ALDBExpr ALDBProperty::group_concat(bool distinct) const {
    return ALDBExpr(*this).group_concat(distinct);
}

ALDBExpr ALDBProperty::group_concat(const ALDBExpr &seperator, bool distinct) const {
    return ALDBExpr(*this).group_concat(seperator, distinct);
}

ALDBExpr ALDBProperty::max(bool distinct) const {
    return ALDBExpr(*this).max(distinct);
}

ALDBExpr ALDBProperty::min(bool distinct) const {
    return ALDBExpr(*this).min(distinct);
}

ALDBExpr ALDBProperty::sum(bool distinct) const {
    return ALDBExpr(*this).sum(distinct);
}

ALDBExpr ALDBProperty::total(bool distinct) const {
    return ALDBExpr(*this).total(distinct);
}

//core functions
ALDBExpr ALDBProperty::abs() const {
    return ALDBExpr(*this).abs();
}

ALDBExpr ALDBProperty::length() const {
    return ALDBExpr(*this).length();
}

ALDBExpr ALDBProperty::lower() const {
    return ALDBExpr(*this).lower();
}

ALDBExpr ALDBProperty::upper() const {
    return ALDBExpr(*this).upper();
}

ALDBExpr ALDBProperty::round(bool distinct) const {
    return ALDBExpr(*this).round(distinct);
}

ALDBExpr ALDBProperty::hex(bool distinct) const {
    return ALDBExpr(*this).hex(distinct);
}

// ALDBExpr.instr(str) => "INSTR(str, ALDBExpr)"
ALDBExpr ALDBProperty::instr(const ALDBExpr &str) const {
    return ALDBExpr(*this).instr(str);
}

ALDBExpr ALDBProperty::substr(const ALDBExpr &from) const {
    return ALDBExpr(*this).substr(from);
}

ALDBExpr ALDBProperty::substr(const ALDBExpr &from, const ALDBExpr &len) const {
    return ALDBExpr(*this).substr(from, len);
}

ALDBExpr ALDBProperty::replace(const ALDBExpr &find, const ALDBExpr &replacement) const {
    return ALDBExpr(*this).replace(find, replacement);
}

ALDBExpr ALDBProperty::ltrim() const {
    return ALDBExpr(*this).ltrim();
}

ALDBExpr ALDBProperty::ltrim(const ALDBExpr &trim_str) const {
    return ALDBExpr(*this).ltrim(trim_str);
}

ALDBExpr ALDBProperty::rtrim() const {
    return ALDBExpr(*this).rtrim();
}

ALDBExpr ALDBProperty::rtrim(const ALDBExpr &trim_str) const {
    return ALDBExpr(*this).rtrim(trim_str);
}

ALDBExpr ALDBProperty::trim() const {
    return ALDBExpr(*this).trim();
}

ALDBExpr ALDBProperty::trim(const ALDBExpr &trim_str) const {
    return ALDBExpr(*this).trim(trim_str);
}


#pragma mark - ALDBPropertyList

ALDBPropertyList::ALDBPropertyList() : std::list<const ALDBProperty>() {
}

ALDBPropertyList::ALDBPropertyList(const ALDBProperty &property) : std::list<const ALDBProperty>({property}) {
}

ALDBPropertyList::ALDBPropertyList(std::initializer_list<const ALDBProperty> list)
    : std::list<const ALDBProperty>(list) {
}

ALDBPropertyList ALDBPropertyList::inTable(NSString *tableName) const {
    ALDBPropertyList propertyList;
    for (auto iter : *this) {
        propertyList.push_back(iter.inTable(tableName));
    }
    return propertyList;
}
