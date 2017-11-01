//
//  expr.cpp
//  alloy
//
//  Created by Alex Lee on 29/09/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#include "expr.hpp"
#include "column.hpp"
#include "sql_value.hpp"
#include "sql_select.hpp"

namespace aldb {

const std::string Expr::_s_param_placeholder = "?";
const aldb::Expr Expr::BIND_PARAM = Expr(Column(_s_param_placeholder));
const ExprPrecedence Expr::DEFAULT_PRECEDENCE = 0;

Expr::Expr():
        SQLClause(),
        _precedence(DEFAULT_PRECEDENCE) {
}

Expr::Expr(const Column &column):
        SQLClause(column.name()),
        _precedence(DEFAULT_PRECEDENCE){
}

Expr::Expr(const std::string &column, const SQLValue &value):
        SQLClause(column, {value}),
        _precedence(DEFAULT_PRECEDENCE) {
}
Expr::Expr(long value) :
        SQLClause(_s_param_placeholder, {value}),
        _precedence(DEFAULT_PRECEDENCE) {
}

Expr::Expr(const char *value):
        SQLClause(_s_param_placeholder, {value}),
        _precedence(DEFAULT_PRECEDENCE) {
}
    
Expr::Expr(const std::string &value):
        SQLClause(_s_param_placeholder, {value}),
        _precedence(DEFAULT_PRECEDENCE) {
}
    
Expr::Expr(const SQLValue &value):
        SQLClause(_s_param_placeholder, {value}),
        _precedence(DEFAULT_PRECEDENCE) {
}
    
Expr::Expr(const void *bytes, size_t size):
        SQLClause(_s_param_placeholder, {SQLValue(bytes, size)}),
        _precedence(DEFAULT_PRECEDENCE) {
}

Expr::Expr(const std::nullptr_t &value):
        SQLClause(_s_param_placeholder, {value}),
        _precedence(DEFAULT_PRECEDENCE) {
}
    
Expr::Expr(const Expr &other):
        SQLClause(other),
        _precedence(other._precedence) {
}

Expr &Expr::operator=(const Expr &other) {
    if (this != &other) {
        SQLClause::operator=(other);
        _precedence        = other._precedence;
    }
    return *this;
}

#pragma mark - sql opetations
//@link: http://www.sqlite.org/lang_expr.html
// unary
Expr Expr::operator!() const {
    Expr expr(*this);
    expr._sql.insert(0, "NOT (").append(")");
    return expr;
}

Expr Expr::operator+() const {
    return *this;
}

Expr Expr::operator-() const {
    Expr expr(*this);
    expr._sql.insert(0, "-(").append(")");
    return expr;
}

Expr Expr::operator~() const {
    Expr expr(*this);
    expr._sql.insert(0, "~(").append(")");
    return expr;
}

#pragma mark - binary

#define expr_operate(other, optr)      \
    ({                                 \
        Expr expr(*this);              \
        expr.operation((other), optr); \
        expr;                          \
    })

Expr Expr::operator||(const Expr &r) const {  // or, not concat
    return expr_operate(r, "OR");
}

Expr Expr::operator&&(const Expr &r) const { return expr_operate(r, "AND"); }

Expr Expr::operator*(const Expr &r) const { return expr_operate(r, "*"); }

Expr Expr::operator/(const Expr &r) const { return expr_operate(r, "/"); }

Expr Expr::operator%(const Expr &r) const { return expr_operate(r, "%"); }

Expr Expr::operator+(const Expr &r) const { return expr_operate(r, "+"); }

Expr Expr::operator-(const Expr &r) const { return expr_operate(r, "-"); }

Expr Expr::operator<<(const Expr &r) const { return expr_operate(r, "<<"); }

Expr Expr::operator>>(const Expr &r) const { return expr_operate(r, ">>"); }

Expr Expr::operator&(const Expr &r) const { return expr_operate(r, "&"); }

Expr Expr::operator|(const Expr &r) const { return expr_operate(r, "|"); }

Expr Expr::operator<(const Expr &r) const { return expr_operate(r, "<"); }

Expr Expr::operator<=(const Expr &r) const { return expr_operate(r, "<="); }

Expr Expr::operator>(const Expr &r) const { return expr_operate(r, ">"); }

Expr Expr::operator>=(const Expr &r) const { return expr_operate(r, ">="); }

Expr Expr::operator==(const Expr &r) const { return expr_operate(r, "="); }

Expr Expr::operator!=(const Expr &r) const { return expr_operate(r, "!="); }


Expr Expr::in(const std::string &table_name) const {
    Expr expr(*this);
    expr.append(" IN " + table_name);
    expr._precedence = operator_precedence_map().at("IN");
    return expr;
}

Expr Expr::in(const SQLSelect &select) const {
    Expr expr(*this);
    expr.append(" IN (").append(select).append(")");
    expr._precedence = operator_precedence_map().at("IN");
    return expr;
}

Expr Expr::not_in(const std::string &table_name) const {
    Expr expr(*this);
    expr.append(" NOT IN " + table_name);
    expr._precedence = operator_precedence_map().at("IN");
    return expr;
}

Expr Expr::not_in(const SQLSelect &select) const {
    Expr expr(*this);
    expr.append(" NOT IN (").append(select).append(")");
    expr._precedence = operator_precedence_map().at("IN");
    return expr;
}

Expr Expr::between(const Expr &left, const Expr &right) const {
    Expr expr(*this);
    expr.append(" BETWEEN (").append(left).append(") AND (").append(right).append(")");
    //@link: http://www.sqlite.org/lang_expr.html (The BETWEEN operator)
    expr._precedence = operator_precedence("LIKE");
    return expr;
}

Expr Expr::not_between(const Expr &left, const Expr &right) const {
    Expr expr(*this);
    expr.append(" NOT BETWEEN (").append(left).append(") AND (").append(right).append(")");
    //@link: http://www.sqlite.org/lang_expr.html (The BETWEEN operator)
    expr._precedence = operator_precedence("LIKE");
    return expr;
}

Expr Expr::like(const Expr &expr) const {
    return expr_operate(expr, "LIKE");
}

Expr Expr::not_like(const Expr &expr) const {
    Expr likeClause(*this);
    likeClause.operation(expr, "NOT LIKE", operator_precedence("LIKE"));
    return likeClause;
}

Expr Expr::like(const Expr &expr, const Expr &escape) const {
    Expr likeExpr(expr);
    if (!escape.empty()) {
        likeExpr.append(" ESCAPE ");
        likeExpr.append(escape);
    }
    return expr_operate(likeExpr, "LIKE");
}

Expr Expr::not_like(const Expr &expr, const Expr &escape) const {
    Expr likeExpr(expr);
    if (!escape.empty()) {
        likeExpr.append(" ESCAPE ");
        likeExpr.append(escape);
    }

    Expr likeClause(*this);
    likeClause.operation(likeExpr, "NOT LIKE", operator_precedence("LIKE"));
    return likeClause;
}

Expr Expr::glob(const Expr &expr) const {
    return expr_operate(expr, "GLOB");
}

Expr Expr::not_glob(const Expr &expr) const {
    Expr likeClause(*this);
    likeClause.operation(expr, "NOT GLOB", operator_precedence("GLOB"));
    return likeClause;
}

Expr Expr::glob(const Expr &expr, const Expr &escape) const {
    Expr likeExpr(expr);
    if (!escape.empty()) {
        likeExpr.append(" ESCAPE ");
        likeExpr.append(escape);
    }
    return expr_operate(likeExpr, "GLOB");
}

Expr Expr::not_glob(const Expr &expr, const Expr &escape) const {
    Expr likeExpr(expr);
    if (!escape.empty()) {
        likeExpr.append(" ESCAPE ");
        likeExpr.append(escape);
    }

    Expr likeClause(*this);
    likeClause.operation(likeExpr, "NOT GLOB", operator_precedence("GLOB"));
    return likeClause;
}

Expr Expr::match(const Expr &expr) const {
    return expr_operate(expr, "MATCH");
}

Expr Expr::not_match(const Expr &expr) const {
    Expr likeClause(*this);
    likeClause.operation(expr, "NOT MATCH", operator_precedence("MATCH"));
    return likeClause;
}

Expr Expr::match(const Expr &expr, const Expr &escape) const {
    Expr likeExpr(expr);
    if (!escape.empty()) {
        likeExpr.append(" ESCAPE ");
        likeExpr.append(escape);
    }
    return expr_operate(likeExpr, "MATCH");
}

Expr Expr::not_match(const Expr &expr, const Expr &escape) const {
    Expr likeExpr(expr);
    if (!escape.empty()) {
        likeExpr.append(" ESCAPE ");
        likeExpr.append(escape);
    }

    Expr likeClause(*this);
    likeClause.operation(likeExpr, "NOT MATCH", operator_precedence("MATCH"));
    return likeClause;
}

Expr Expr::regexp(const Expr &expr) const {
    return expr_operate(expr, "REGEXP");
}

Expr Expr::not_regexp(const Expr &expr) const {
    Expr likeClause(*this);
    likeClause.operation(expr, "NOT REGEXP", operator_precedence("REGEXP"));
    return likeClause;
}

Expr Expr::regexp(const Expr &expr, const Expr &escape) const {
    Expr likeExpr(expr);
    if (!escape.empty()) {
        likeExpr.append(" ESCAPE ");
        likeExpr.append(escape);
    }
    return expr_operate(likeExpr, "REGEXP");
}

Expr Expr::not_regexp(const Expr &expr, const Expr &escape) const {
    Expr likeExpr(expr);
    if (!escape.empty()) {
        likeExpr.append(" ESCAPE ");
        likeExpr.append(escape);
    }

    Expr likeClause(*this);
    likeClause.operation(likeExpr, "NOT REGEXP", operator_precedence("REGEXP"));
    return likeClause;
}

Expr Expr::is_null() const {
    Expr expr(*this);
    expr.append(" ISNULL");
    return expr;
}

Expr Expr::not_null() const {
    Expr expr(*this);
    expr.append(" NOTNULL");
    return expr;
}

Expr Expr::is(const Expr &expr) const {
    return expr_operate(expr, "IS");
}

Expr Expr::is_not(const Expr &expr) const {
    return expr_operate(expr, "IS NOT");
}

Expr Expr::cast_as(const std::string &type_name) const {
    Expr castExpr;
    castExpr.append("CAST (").append(*this).append(" AS ").append(type_name).append(")");
    return castExpr;
}

Expr Expr::cast_as(const aldb::ColumnType type) const {
    return cast_as(aldb::column_type_name(type));
}

#pragma mark - functions

Expr Expr::function(const std::string &name, bool distinct) const {
    return Expr::function(name, {*this}, distinct);
}
// operation
Expr Expr::concat(const Expr &expr) const {  // "abc"||"def"
    return expr_operate(expr, "||");
}

// aggregate functions
Expr Expr::avg(bool distinct) const {
    return Expr::function("AVG", {*this}, distinct);
}

Expr Expr::count(bool distinct) const {
    return Expr::function("COUNT", {*this}, distinct);
}

Expr Expr::group_concat(bool distinct) const {
    return Expr::function("GROUP_CONCAT", {*this}, distinct);
}

Expr Expr::group_concat(const Expr &seperator, bool distinct) const {
    return Expr::function("GROUP_CONCAT", {*this, seperator}, distinct);
}

Expr Expr::max(bool distinct) const {
    return Expr::function("MAX", {*this}, distinct);
}

Expr Expr::min(bool distinct) const {
    return Expr::function("MIN", {*this}, distinct);
}

Expr Expr::sum(bool distinct) const {
    return Expr::function("SUM", {*this}, distinct);
}

Expr Expr::total(bool distinct) const {
    return Expr::function("TOTAL", {*this}, distinct);
}

// core functions
Expr Expr::abs() const {
    return Expr::function("ABS", {*this});
}

Expr Expr::length() const {
    return Expr::function("LENGTH", {*this});
}

Expr Expr::lower() const {
    return Expr::function("LOWER", {*this});
}

Expr Expr::upper() const {
    return Expr::function("UPPER", {*this});
}

Expr Expr::round(bool distinct) const {
    return Expr::function("ROUND", {*this});
}

Expr Expr::hex(bool distinct) const {
    return Expr::function("HEX", {*this});
}

// expr.instr(str) => "INSTR(str, expr)"
Expr Expr::instr(const Expr &str) const {
    return Expr::function("INSTR", {str, *this});
}

Expr Expr::substr(const Expr &from) const {
    return Expr::function("SUBSTR", {*this, from});
}

Expr Expr::substr(const Expr &from, const Expr &len) const {
    return Expr::function("SUBSTR", {*this, from, len});
}

Expr Expr::replace(const Expr &find, const Expr &replacement) const {
    return Expr::function("REPLACE", {*this, find, replacement});
}

Expr Expr::ltrim() const {
    return Expr::function("LTRIM", {*this});
}

Expr Expr::ltrim(const Expr &trim_str) const {
    return Expr::function("LTRIM", {*this, trim_str});
}

Expr Expr::rtrim() const {
    return Expr::function("RTRIM", {*this});
}

Expr Expr::rtrim(const Expr &trim_str) const {
    return Expr::function("RTRIM", {*this, trim_str});
}

Expr Expr::trim() const {
    return Expr::function("TRIM", {*this});
}

Expr Expr::trim(const Expr &trim_str) const {
    return Expr::function("TRIM", {*this, trim_str});
}

#pragma mark -
/**
 *  @see: http://www.sqlite.org/lang_expr.html
 SQLite understands the following binary operators, in order from highest to lowest precedence:

 ||
 *    /    %
 +    -
 <<   >>   &    |
 <    <=   >    >=
 =    ==   !=   <>   IS   IS NOT   IN   LIKE   GLOB   MATCH   REGEXP
 AND
 OR

 Supported unary prefix operators are these:

 -    +    ~    NOT

 *
 */
const std::unordered_map<std::string, int> &Expr::operator_precedence_map() {
    static const std::unordered_map<std::string, int> map = {
        {"||", 1},   {"*", 2},    {"/", 2},     {"%", 2},      {"+", 3},   {"-", 3},      {"<<", 4},
        {">>", 4},   {"&", 4},    {"|", 4},     {"<", 5},      {"<=", 5},  {">", 5},      {">=", 5},
        {"=", 6},    {"==", 6},   {"!=", 6},    {"<>", 6},     {"IS", 6},  {"IS NOT", 6}, {"IN", 6},
        {"LIKE", 6}, {"GLOB", 6}, {"MATCH", 6}, {"REGEXP", 6}, {"AND", 7}, {"OR", 8}};
    return map;
}

ExprPrecedence Expr::operator_precedence(const std::string &optr) {
    ExprPrecedence p = DEFAULT_PRECEDENCE;
    auto iter = operator_precedence_map().find(optr);
    if (iter != operator_precedence_map().end()) {
        p = iter->second;
    }
    return p;
}

void Expr::operation(const Expr &other, const std::string &optr, ExprPrecedence optr_precedence) {
    if (this->empty()) {
        append(other);
        _precedence = other._precedence;
        return;
    } else if (other.empty()) {
        return;
    }

    ExprPrecedence p = optr_precedence;
    if (p == DEFAULT_PRECEDENCE) {
        p = operator_precedence(optr);
    }

    if (p != DEFAULT_PRECEDENCE && p < _precedence) {
        SQLClause::parenthesized();
    }
    if (p != DEFAULT_PRECEDENCE && p < other._precedence) {
        //bracketed `other`
        SQLClause::append(" ").append(optr).append(" (").append(other).append(")");
    } else {
        SQLClause::append(" ").append(optr).append(" ").append(other);
    }
    _precedence = p;
}
    
}
