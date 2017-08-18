//
//  ALSQLExpr.m
//  alloy
//
//  Created by Alex Lee on 03/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALSQLExpr.h"
#import "ALDBColumn.h"
#import "ALSQLValue.h"

const ALDBOptrPrecedence ALSQLExpr::s_default_precedence = 0;
const ALSQLExpr ALSQLExpr::s_null_expr = ALSQLExpr();

ALSQLExpr::ALSQLExpr() : ALSQLClause(), _precedence(s_default_precedence) {}

ALSQLExpr::ALSQLExpr(const ALDBColumn &column) : ALSQLClause(std::string(column)), _precedence(s_default_precedence) {}

ALSQLExpr::ALSQLExpr(const ALSQLValue &value) : ALSQLClause("?", {value}), _precedence(s_default_precedence) {}

ALSQLExpr::ALSQLExpr(const ALSQLExpr &expr) : ALSQLClause(expr), _precedence(expr._precedence) {}

ALSQLExpr::ALSQLExpr(const char *value)
    : ALSQLClause("?", {ALSQLValue(value ? value : "")}), _precedence(s_default_precedence) {}

ALSQLExpr::ALSQLExpr(const std::string &value) : ALSQLClause("?", {value}), _precedence(s_default_precedence) {}

ALSQLExpr::ALSQLExpr(const std::nullptr_t &) : ALSQLClause("NULL"), _precedence(s_default_precedence) {}

ALSQLExpr::ALSQLExpr(id value) : ALSQLClause("?", {value}), _precedence(s_default_precedence) {}

//ALSQLExpr::operator bool() const { return !is_empty(); }

ALSQLExpr::operator std::list<const ALSQLExpr>() const { return {*this};}

//ALSQLExpr::operator ALSQLClause() const { return _clause; }
//
//const ALSQLClause &ALSQLExpr::SQLClause() const { return _clause; }

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
const std::unordered_map<std::string, int> &ALSQLExpr::operator_precedence_map() {
    static const std::unordered_map<std::string, int> map = {
        {"||", 1},   {"*", 2},    {"/", 2},     {"%", 2},      {"+", 3},   {"-", 3},      {"<<", 4},
        {">>", 4},   {"&", 4},    {"|", 4},     {"<", 5},      {"<=", 5},  {">", 5},      {">=", 5},
        {"=", 6},    {"==", 6},   {"!=", 6},    {"<>", 6},     {"IS", 6},  {"IS NOT", 6}, {"IN", 6},
        {"LIKE", 6}, {"GLOB", 6}, {"MATCH", 6}, {"REGEXP", 6}, {"AND", 7}, {"OR", 8}};
    return map;
}

ALDBOptrPrecedence ALSQLExpr::operator_precedence(const std::string &optr) {
    ALDBOptrPrecedence p = s_default_precedence;
    auto iter = operator_precedence_map().find(optr);
    if (iter != operator_precedence_map().end()) {
        p = iter->second;
    }
    return p;
}

void ALSQLExpr::operate_with(const ALSQLExpr &other, const std::string &optr, ALDBOptrPrecedence optr_precedence) {
    ALDBOptrPrecedence p = optr_precedence;
    if (p == s_default_precedence) {
        p = operator_precedence(optr);
    }

    if (p != s_default_precedence && p < _precedence) {
        enclode_with_brackets();
    }
    if (p != s_default_precedence && p < other._precedence) {
        ALSQLClause::append(" " + optr + " (");
        ALSQLClause::append(other);
        ALSQLClause::append(")");
    } else {
        ALSQLClause::append(" " + optr + " ");
        ALSQLClause::append(other);
    }
    _precedence = p;
}

void ALSQLExpr::enclode_with_brackets() {
    _sql = "("+ _sql +")";
}


#pragma mark - unary
ALSQLExpr ALSQLExpr::operator!() const {
    ALSQLExpr expr(*this);
    expr._sql = "NOT ("+expr._sql+")";
    return expr;
}

ALSQLExpr ALSQLExpr::operator+() const {
    return ALSQLExpr(*this);
}

ALSQLExpr ALSQLExpr::operator-() const {
    ALSQLExpr expr(*this);
    expr._sql = "-("+expr._sql+")";
    return expr;
}

ALSQLExpr ALSQLExpr::operator~() const {
    ALSQLExpr expr(*this);
    expr._sql = "~("+expr._sql+")";
    return expr;
}

#pragma mark - binary

#define expr_operate(other, optr)         \
    ({                                    \
        ALSQLExpr expr(*this);            \
        expr.operate_with((other), optr); \
        expr;                             \
    })

ALSQLExpr ALSQLExpr::operator||(const ALSQLExpr &r) const {  // or, not concat
    return expr_operate(r, "OR");
}

ALSQLExpr ALSQLExpr::operator&&(const ALSQLExpr &r) const {
    return expr_operate(r, "AND");
}

ALSQLExpr ALSQLExpr::operator*(const ALSQLExpr &r) const {
    return expr_operate(r, "*");
}

ALSQLExpr ALSQLExpr::operator/(const ALSQLExpr &r) const {
    return expr_operate(r, "/");
}

ALSQLExpr ALSQLExpr::operator%(const ALSQLExpr &r) const {
    return expr_operate(r, "%");
}

ALSQLExpr ALSQLExpr::operator+(const ALSQLExpr &r) const {
    return expr_operate(r, "+");
}

ALSQLExpr ALSQLExpr::operator-(const ALSQLExpr &r) const {
    return expr_operate(r, "-");
}

ALSQLExpr ALSQLExpr::operator<<(const ALSQLExpr &r) const {
    return expr_operate(r, "<<");
}

ALSQLExpr ALSQLExpr::operator>>(const ALSQLExpr &r) const {
    return expr_operate(r, ">>");
}

ALSQLExpr ALSQLExpr::operator&(const ALSQLExpr &r) const {
    return expr_operate(r, "&");
}

ALSQLExpr ALSQLExpr::operator|(const ALSQLExpr &r) const {
    return expr_operate(r, "|");
}

ALSQLExpr ALSQLExpr::operator<(const ALSQLExpr &r) const {
    return expr_operate(r, "<");
}

ALSQLExpr ALSQLExpr::operator<=(const ALSQLExpr &r) const {
    return expr_operate(r, "<=");
}

ALSQLExpr ALSQLExpr::operator>(const ALSQLExpr &r) const {
    return expr_operate(r, ">");
}

ALSQLExpr ALSQLExpr::operator>=(const ALSQLExpr &r) const {
    return expr_operate(r, ">=");
}

ALSQLExpr ALSQLExpr::operator==(const ALSQLExpr &r) const {
    return expr_operate(r, "=");
}

ALSQLExpr ALSQLExpr::operator!=(const ALSQLExpr &r) const {
    return expr_operate(r, "!=");
}

ALSQLExpr ALSQLExpr::in(const std::list<const ALSQLExpr> &expr_list) const {
    ALSQLExpr inclause = ALSQLClause::combine<ALSQLExpr>(expr_list, ", ");
    inclause.enclode_with_brackets();
    
    return expr_operate(inclause, "IN");
}

ALSQLExpr ALSQLExpr::in(const std::string &table_name) const {
    ALSQLExpr expr(*this);
    expr.append(" IN " + table_name);
    expr._precedence = operator_precedence_map().at("IN");
    return expr;
}
//    ALSQLExpr in(const SelectStatement &stmt) const;
ALSQLExpr ALSQLExpr::not_in(const std::list<const ALSQLExpr> &expr_list) const {
    ALSQLExpr inclause = ALSQLClause::combine<ALSQLExpr>(expr_list, ", ");
    inclause.enclode_with_brackets();
    
    ALSQLExpr expr(*this);
    expr.operate_with(inclause, "NOT IN", operator_precedence("IN"));
    return expr;
}

ALSQLExpr ALSQLExpr::not_in(const std::string &table_name) const {
    ALSQLExpr expr(*this);
    expr.append(" NOT IN " + table_name);
    expr._precedence = operator_precedence_map().at("IN");
    return expr;
}
//ALSQLExpr not_in(const char *table_name) const;

ALSQLExpr ALSQLExpr::like(const ALSQLExpr &expr, const ALSQLExpr &escape) const {
    ALSQLExpr likeExpr(expr);
    if (!escape.is_empty()) {
        likeExpr.append(" ESCAPE ");
        likeExpr.append(escape);
    }
    return expr_operate(likeExpr, "LIKE");
}

ALSQLExpr ALSQLExpr::not_like(const ALSQLExpr &expr, const ALSQLExpr &escape) const {
    ALSQLExpr likeExpr(expr);
    if (!escape.is_empty()) {
        likeExpr.append(" ESCAPE ");
        likeExpr.append(escape);
    }
    
    ALSQLExpr likeClause(*this);
    likeClause.operate_with(likeExpr, "NOT LIKE", operator_precedence("LIKE"));
    return likeClause;
}

ALSQLExpr ALSQLExpr::is_null() const {
    ALSQLExpr expr(*this);
    expr.append(" ISNULL");
    return expr;
}

ALSQLExpr ALSQLExpr::not_null() const {
    ALSQLExpr expr(*this);
    expr.append(" NOTNULL");
    return expr;
}

ALSQLExpr ALSQLExpr::is(const ALSQLExpr &expr) const {
    return expr_operate(expr, "IS");
}

ALSQLExpr ALSQLExpr::is_not(const ALSQLExpr &expr) const {
    return expr_operate(expr, "IS NOT");
}

ALSQLExpr ALSQLExpr::cast_as(const ALSQLExpr &expr, const std::string &type_name) {
    ALSQLExpr castExpr;
    castExpr.append("CAST (");
    castExpr.append(expr);
    castExpr.append(" AS " + type_name + ")");
    return castExpr;
}

ALSQLExpr cast_as(const ALSQLExpr &expr, const ALDBColumnType type) {
    return ALSQLExpr::cast_as(expr, aldb::column_type_name((aldb::ColumnType)type));
}
//    static ALSQLExpr exists(const SelectStatement &stmt);
//    static ALSQLExpr not_exists(const SelectStatement &stmt);

// case a when b then c else d end
ALSQLExpr ALSQLExpr::case_clause(const ALSQLExpr &expr,
                             const std::list<const std::pair<const ALSQLExpr, const ALSQLExpr>> &when_then,
                             const ALSQLExpr &else_value) {
    ALSQLExpr caseExpr;
    caseExpr.append("CASE ");
    if (!expr.is_empty()) {
        caseExpr.append(expr);
    }
    
    for (auto &pair : when_then) {
        caseExpr.append(" WHEN ");
        caseExpr.append(pair.first);
        caseExpr.append(" THEN ");
        caseExpr.append(pair.second);
    }
    if (!else_value.is_empty()) {
        caseExpr.append(" ELSE ");
        caseExpr.append(else_value);
    }
    caseExpr.append(" END");
    return caseExpr;
}

ALSQLExpr ALSQLExpr::case_clause(const std::list<const std::pair<const ALSQLExpr, const ALSQLExpr>> &when_then,
                                 const ALSQLExpr &else_value) {
    return ALSQLExpr::case_clause(s_null_expr, when_then, else_value);
}


#pragma mark - functions
ALSQLExpr ALSQLExpr::function(const std::string &fun_name, const std::list<const ALSQLExpr> &args, bool distinct) {
    std::string upper_name = aldb::str_to_upper(fun_name);
    
    ALSQLExpr funcExpr;
    funcExpr.append(upper_name + "(");
    if (distinct) {
        funcExpr.append("DISTINCT ");
    }
    funcExpr.append(combine(args, ", "));
    funcExpr.append(")");
    return funcExpr;
}

ALSQLExpr ALSQLExpr::concat(const ALSQLExpr &expr) const { // "abc"||"def"
    return expr_operate(expr, "||");
}

ALSQLExpr ALSQLExpr::abs() const {
    return ALSQLExpr::function("ABS", {*this});
}

ALSQLExpr ALSQLExpr::length() const {
    return ALSQLExpr::function("LENGTH", {*this});
}

ALSQLExpr ALSQLExpr::lower() const {
    return ALSQLExpr::function("LOWER", {*this});
}

ALSQLExpr ALSQLExpr::upper() const {
    return ALSQLExpr::function("UPPER", {*this});
}

// expr.instr(str) => "INSTR(str, expr)"
ALSQLExpr ALSQLExpr::instr(const ALSQLExpr &str) const {
    return ALSQLExpr::function("INSTR", {str, *this});
}
ALSQLExpr ALSQLExpr::substr(const ALSQLExpr &from) const {
    return ALSQLExpr::function("SUBSTR", {*this, from});
}

ALSQLExpr ALSQLExpr::substr(const ALSQLExpr &from, const ALSQLExpr &len) const {
    return ALSQLExpr::function("SUBSTR", {*this, from, len});
}

ALSQLExpr ALSQLExpr::replace(const ALSQLExpr &find, const ALSQLExpr &replacement) const {
    return ALSQLExpr::function("REPLACE", {*this, find, replacement});
}

ALSQLExpr ALSQLExpr::ltrim() const {
    return ALSQLExpr::function("LTRIM", {*this});
}

ALSQLExpr ALSQLExpr::ltrim(const ALSQLExpr &trim_str) const {
    return ALSQLExpr::function("LTRIM", {*this, trim_str});
}

ALSQLExpr ALSQLExpr::rtrim() const {
    return ALSQLExpr::function("RTRIM", {*this});
}

ALSQLExpr ALSQLExpr::rtrim(const ALSQLExpr &trim_str) const {
    return ALSQLExpr::function("RTRIM", {*this, trim_str});
}

ALSQLExpr ALSQLExpr::trim() const {
    return ALSQLExpr::function("TRIM", {*this});
}

ALSQLExpr ALSQLExpr::trim(const ALSQLExpr &trim_str) const {
    return ALSQLExpr::function("TRIM", {*this, trim_str});
}

ALSQLExpr ALSQLExpr::avg(bool distinct) const {
    return ALSQLExpr::function("AVG", {*this}, distinct);
}

ALSQLExpr ALSQLExpr::count(bool distinct) const {
    return ALSQLExpr::function("COUNT", {*this}, distinct);
}

ALSQLExpr ALSQLExpr::groupConcat(bool distinct) const {
    return ALSQLExpr::function("GROUP_CONCAT", {*this}, distinct);
}

ALSQLExpr ALSQLExpr::groupConcat(const ALSQLExpr &seperator, bool distinct) const {
    return ALSQLExpr::function("GROUP_CONCAT", {*this, seperator}, distinct);
}

ALSQLExpr ALSQLExpr::max(bool distinct) const {
    return ALSQLExpr::function("MAX", {*this}, distinct);
}

ALSQLExpr ALSQLExpr::min(bool distinct) const {
    return ALSQLExpr::function("MIN", {*this}, distinct);
}

ALSQLExpr ALSQLExpr::sum(bool distinct) const {
    return ALSQLExpr::function("SUM", {*this}, distinct);
}

ALSQLExpr ALSQLExpr::total(bool distinct) const {
    return ALSQLExpr::function("TOTAL", {*this}, distinct);
}



