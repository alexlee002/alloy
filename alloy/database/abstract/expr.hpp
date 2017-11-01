//
//  expr.hpp
//  alloy
//
//  Created by Alex Lee on 29/09/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//
//  Fork from WCDB, github: https://github.com/tencent/wcdb
//

#ifndef expr_hpp
#define expr_hpp

#include <stdio.h>
#include <string>
#include <unordered_map>
#include "defines.hpp"
#include "sql_clause.hpp"

namespace aldb {

class Column;
class SQLSelect;
    
class Expr : public SQLClause {
  public:
    static const Expr BIND_PARAM;
    static const ExprPrecedence DEFAULT_PRECEDENCE;

    Expr();
    Expr(const std::string &column, const SQLValue &value);
    Expr(const Column &column);
    Expr(const Expr &other);

    template <typename T>
    Expr(const T &value,
         typename std::enable_if<std::is_arithmetic<T>::value || std::is_enum<T>::value>::type * = nullptr)
        : SQLClause(_s_param_placeholder, {value}), _precedence(DEFAULT_PRECEDENCE) {
    }

    Expr(long value);
    Expr(const char *value);
    Expr(const std::string &value);
    Expr(const SQLValue &value);
    Expr(const void *bytes, size_t size);
    Expr(const std::nullptr_t &value);

    Expr &operator=(const Expr &other);

#pragma mark - sql opetations
    //@link: http://www.sqlite.org/lang_expr.html
    // unary
    Expr operator!() const;
    Expr operator+() const;
    Expr operator-() const;
    Expr operator~() const;

    // binary
    Expr operator||(const Expr &r) const;  // or, not concat
    Expr operator&&(const Expr &r) const;
    Expr operator*(const Expr &r) const;
    Expr operator/(const Expr &r) const;
    Expr operator%(const Expr &r) const;
    Expr operator+(const Expr &r) const;
    Expr operator-(const Expr &r) const;
    Expr operator<<(const Expr &r) const;
    Expr operator>>(const Expr &r) const;
    Expr operator&(const Expr &r) const;
    Expr operator|(const Expr &r) const;
    Expr operator<(const Expr &r) const;
    Expr operator<=(const Expr &r) const;
    Expr operator>(const Expr &r) const;
    Expr operator>=(const Expr &r) const;
    Expr operator==(const Expr &r) const;
    Expr operator!=(const Expr &r) const;

    template <typename T = Expr>
    typename std::enable_if<std::is_base_of<Expr, T>::value, Expr>::type
    in(const std::list<const T> &expr_list) const  {
        Expr expr(SQLClause::combine<Expr>(expr_list, ", "));
        expr.parenthesized();
        
        Expr ret(*this);
        ret.operation(expr, "IN");
        return ret;
    }

    Expr in(const std::string &table_name) const;
    Expr in(const SQLSelect &select) const;
    
    template <typename T = Expr>
    typename std::enable_if<std::is_base_of<Expr, T>::value, Expr>::type
    not_in(const std::list<const T> &expr_list) const  {
        Expr inclause = SQLClause::combine<Expr>(expr_list, ", ");
        inclause.parenthesized();
        
        Expr expr(*this);
        expr.operation(inclause, "NOT IN", operator_precedence("IN"));
        return expr;
    }
    
    Expr not_in(const std::string &table_name) const;
    Expr not_in(const SQLSelect &select) const;
    Expr between(const Expr &left, const Expr &right) const;
    Expr not_between(const Expr &left, const Expr &right) const;

    Expr like(const Expr &expr) const;
    Expr not_like(const Expr &expr) const;
    Expr like(const Expr &expr, const Expr &escape) const;
    Expr not_like(const Expr &expr, const Expr &escape) const;
    
    Expr glob(const Expr &expr) const;
    Expr not_glob(const Expr &expr) const;
    Expr glob(const Expr &expr, const Expr &escape) const;
    Expr not_glob(const Expr &expr, const Expr &escape) const;
    
    Expr match(const Expr &expr) const;
    Expr not_match(const Expr &expr) const;
    Expr match(const Expr &expr, const Expr &escape) const;
    Expr not_match(const Expr &expr, const Expr &escape) const;
    
    Expr regexp(const Expr &expr) const;
    Expr not_regexp(const Expr &expr) const;
    Expr regexp(const Expr &expr, const Expr &escape) const;
    Expr not_regexp(const Expr &expr, const Expr &escape) const;

    Expr is_null() const;
    Expr not_null() const;
    Expr is(const Expr &expr) const;
    Expr is_not(const Expr &expr) const;

    Expr cast_as(const std::string &type_name) const;
    Expr cast_as(const aldb::ColumnType type) const;
    
    static Expr exists(const SQLSelect &stmt);
    static Expr not_exists(const SQLSelect &stmt);

    // case (*this) when b then c else d end
    template <typename T = Expr>
    typename std::enable_if<std::is_base_of<Expr, T>::value, Expr>::type
    case_when(const std::list<const std::pair<const T, const T>> &when_then) {
        Expr caseExpr;
        caseExpr.append("CASE ").append(*this);
        
        for (auto &pair : when_then) {
            caseExpr.append(" WHEN ").append(pair.first).append(" THEN ").append(pair.second);
        }
        caseExpr.append(" END");
        return caseExpr;
    }
    
    template <typename T = Expr>
    typename std::enable_if<std::is_base_of<Expr, T>::value, Expr>::type
    case_when(const std::list<const std::pair<const T, const T>> &when_then,
              const Expr &else_value)  {
        Expr caseExpr;
        caseExpr.append("CASE ").append(*this);
        
        for (auto &pair : when_then) {
            caseExpr.append(" WHEN ").append(pair.first).append(" THEN ").append(pair.second);
        }
        
        caseExpr.append(" ELSE ").append(else_value).append(" END");
        return caseExpr;
    }
    
    // case when a then b else c end
    template <typename T = Expr>
    static typename std::enable_if<std::is_base_of<Expr, T>::value, Expr>::type
    case_expr(const std::list<const std::pair<const T, const T>> &when_then) {
        Expr caseExpr;
        caseExpr.append("CASE");
        
        for (auto &pair : when_then) {
            caseExpr.append(" WHEN ").append(pair.first).append(" THEN ").append(pair.second);
        }
        
        caseExpr.append(" END");
        return caseExpr;
    }
    
    template <typename T = Expr>
    static typename std::enable_if<std::is_base_of<Expr, T>::value, Expr>::type
    case_expr(const std::list<const std::pair<const T, const T>> &when_then,
              const Expr &else_value) {
        Expr caseExpr;
        caseExpr.append("CASE");
        
        for (auto &pair : when_then) {
            caseExpr.append(" WHEN ").append(pair.first).append(" THEN ").append(pair.second);
        }
        
        caseExpr.append(" ELSE ").append(else_value).append(" END");
        return caseExpr;
    }

#pragma mark - sql functions
    //@link: http://www.sqlite.org/lang_corefunc.html

    template <typename T = Expr>
    static typename std::enable_if<std::is_base_of<Expr, T>::value, Expr>::type
    function(const std::string &fun_name, const std::list<const T> &args, bool distinct = false) {
        std::string upper_name = aldb::str_to_upper(fun_name);
        
        Expr funcExpr;
        funcExpr.append(upper_name).append("(");
        if (distinct) {
            funcExpr.append("DISTINCT ");
        }
        funcExpr.append(combine<Expr>(args, ", "));
        funcExpr.append(")");
        return funcExpr;
    }
    
    Expr function(const std::string &name, bool distinct = false) const;
    //operation
    Expr concat(const Expr &expr) const;  // "abc"||"def"
    
    //aggregate functions
    Expr avg(bool distinct = false) const;
    Expr count(bool distinct = false) const;
    Expr group_concat(bool distinct = false) const;
    Expr group_concat(const Expr &seperator, bool distinct = false) const;
    Expr max(bool distinct = false) const;
    Expr min(bool distinct = false) const;
    Expr sum(bool distinct = false) const;
    Expr total(bool distinct = false) const;
    
    //core functions
    Expr abs() const;
    Expr length() const;
    Expr lower() const;
    Expr upper() const;
    Expr round(bool distinct = false) const;
    Expr hex(bool distinct = false) const;
    // expr.instr(str) => "INSTR(str, expr)"
    Expr instr(const Expr &str) const;
    Expr substr(const Expr &from) const;
    Expr substr(const Expr &from, const Expr &len) const;
    Expr replace(const Expr &find, const Expr &replacement) const;
    Expr ltrim() const;
    Expr ltrim(const Expr &trim_str) const;
    Expr rtrim() const;
    Expr rtrim(const Expr &trim_str) const;
    Expr trim() const;
    Expr trim(const Expr &trim_str) const;
    
    
#pragma mark -
protected:
    static const std::string _s_param_placeholder;
    static const std::unordered_map<std::string, int> &operator_precedence_map();
    static ExprPrecedence operator_precedence(const std::string &optr);
    void operation(const Expr &other,
                   const std::string &optr,
                   ExprPrecedence optr_precedence = DEFAULT_PRECEDENCE);
    
protected:
    ExprPrecedence _precedence;
};
}

#endif /* expr_hpp */
