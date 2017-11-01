//
//  ALDBExpr.h
//  alloy
//
//  Created by Alex Lee on 07/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//
//  Fork from WCDB, github: https://github.com/tencent/wcdb
//

#import <UIKit/UIKit.h>
#import "expr.hpp"
#import "ALDBCodingMacros_Private.h"
#import "ALDBTypeDefines.h"
#import "sql_value.hpp"

class ALDBResultColumn;
class ALDBProperty;
class ALDBResultColumnList;
class SQLSelect;
class ALDBExpr : public aldb::Expr {
    __ALDB_PROPERTY_BASE_DEF;
    
public:
    ALDBExpr();
    ALDBExpr(NSString *column, id value);

    template <typename T>
    ALDBExpr(const T &value,
             typename std::enable_if<std::is_arithmetic<T>::value || std::is_enum<T>::value>::type * = nullptr)
        : aldb::Expr(value), __ALDB_PROPERTY_BASE_CTOR(nil, nil) {
    }

    ALDBExpr(const char *value);
    ALDBExpr(long value);
    ALDBExpr(const ALDBProperty &column);
    ALDBExpr(id value);
    ALDBExpr(const aldb::Expr &expr);
    ALDBExpr(const aldb::Expr &expr, /*ALDBProperty(*/Class cls, ALDBColumnBinding *binding /*)*/);
    
    ALDBResultColumn as(const ALDBProperty &property);
    ALDBResultColumnList distinct() const;
    
    ALDBOrderBy order(ALDBOrder order = ALDBOrderDefault);
    
    ALDBExpr &operator=(const ALDBExpr &other);
    
#pragma mark - sql opetations
    //@link: http://www.sqlite.org/lang_expr.html
    // unary
    ALDBExpr operator!() const;
    ALDBExpr operator+() const;
    ALDBExpr operator-() const;
    ALDBExpr operator~() const;
    
    // binary
    ALDBExpr operator||(const ALDBExpr &r) const;  // or, not concat
    ALDBExpr operator&&(const ALDBExpr &r) const;
    ALDBExpr operator*(const ALDBExpr &r) const;
    ALDBExpr operator/(const ALDBExpr &r) const;
    ALDBExpr operator%(const ALDBExpr &r) const;
    ALDBExpr operator+(const ALDBExpr &r) const;
    ALDBExpr operator-(const ALDBExpr &r) const;
    ALDBExpr operator<<(const ALDBExpr &r) const;
    ALDBExpr operator>>(const ALDBExpr &r) const;
    ALDBExpr operator&(const ALDBExpr &r) const;
    ALDBExpr operator|(const ALDBExpr &r) const;
    ALDBExpr operator<(const ALDBExpr &r) const;
    ALDBExpr operator<=(const ALDBExpr &r) const;
    ALDBExpr operator>(const ALDBExpr &r) const;
    ALDBExpr operator>=(const ALDBExpr &r) const;
    ALDBExpr operator==(const ALDBExpr &r) const;
    ALDBExpr operator!=(const ALDBExpr &r) const;
    
    ALDBExpr in(const std::list<const ALDBExpr> &expr_list) const;
    ALDBExpr in(const std::string &table_name) const;
    ALDBExpr in(NSString *table_name) const;
    ALDBExpr in(const aldb::SQLSelect &stmt) const;
    ALDBExpr in(NSArray *values) const;
    ALDBExpr not_in(const std::list<const ALDBExpr> &expr_list) const;
    ALDBExpr not_in(const std::string &table_name) const;
    ALDBExpr not_in(NSString *table_name) const;
    ALDBExpr not_in(const aldb::SQLSelect &stmt) const;
    ALDBExpr not_in(NSArray *values) const;
    ALDBExpr between(const ALDBExpr &left, const ALDBExpr &right) const;
    ALDBExpr not_between(const ALDBExpr &left, const ALDBExpr &right) const;
    
    ALDBExpr like(const ALDBExpr &expr) const;
    ALDBExpr not_like(const ALDBExpr &expr) const;
    ALDBExpr like(const ALDBExpr &expr, const ALDBExpr &escape) const;
    ALDBExpr not_like(const ALDBExpr &expr, const ALDBExpr &escape) const;
    
    ALDBExpr glob(const ALDBExpr &expr) const;
    ALDBExpr not_glob(const ALDBExpr &expr) const;
    ALDBExpr glob(const ALDBExpr &expr, const ALDBExpr &escape) const;
    ALDBExpr not_glob(const ALDBExpr &expr, const ALDBExpr &escape) const;
    
    ALDBExpr match(const ALDBExpr &expr) const;
    ALDBExpr not_match(const ALDBExpr &expr) const;
    ALDBExpr match(const ALDBExpr &expr, const ALDBExpr &escape) const;
    ALDBExpr not_match(const ALDBExpr &expr, const ALDBExpr &escape) const;
    
    ALDBExpr regexp(const ALDBExpr &expr) const;
    ALDBExpr not_regexp(const ALDBExpr &expr) const;
    ALDBExpr regexp(const ALDBExpr &expr, const ALDBExpr &escape) const;
    ALDBExpr not_regexp(const ALDBExpr &expr, const ALDBExpr &escape) const;
    
    ALDBExpr is_null() const;
    ALDBExpr not_null() const;
    ALDBExpr is(const ALDBExpr &expr) const;
    ALDBExpr is_not(const ALDBExpr &expr) const;
    
    ALDBExpr cast_as(const std::string &type_name) const;
    ALDBExpr cast_as(const aldb::ColumnType type) const;
    
    // case (*this) when b then c else d end
    ALDBExpr case_when(const std::list<const std::pair<const ALDBExpr, const ALDBExpr>> &when_then);
    ALDBExpr case_when(const std::list<const std::pair<const ALDBExpr, const ALDBExpr>> &when_then,
                   const ALDBExpr &else_value);
    
    // case when a then b else c end
    static ALDBExpr case_expr(const std::list<const std::pair<const ALDBExpr, const ALDBExpr>> &when_then);
    static ALDBExpr case_expr(const std::list<const std::pair<const ALDBExpr, const ALDBExpr>> &when_then,
                          const ALDBExpr &else_value);
    
#pragma mark - sql functions
    //@link: http://www.sqlite.org/lang_corefunc.html
    
    static ALDBExpr function(const std::string &fun_name, const std::list<const ALDBExpr> &args, bool distinct = false);
    ALDBExpr function(const std::string &name, bool distinct = false) const;
    //operation
    ALDBExpr concat(const ALDBExpr &expr) const;  // "abc"||"def"
    
    //aggregate functions
    ALDBExpr avg(bool distinct = false) const;
    ALDBExpr count(bool distinct = false) const;
    ALDBExpr group_concat(bool distinct = false) const;
    ALDBExpr group_concat(const ALDBExpr &seperator, bool distinct = false) const;
    ALDBExpr max(bool distinct = false) const;
    ALDBExpr min(bool distinct = false) const;
    ALDBExpr sum(bool distinct = false) const;
    ALDBExpr total(bool distinct = false) const;
    
    //core functions
    ALDBExpr abs() const;
    ALDBExpr length() const;
    ALDBExpr lower() const;
    ALDBExpr upper() const;
    ALDBExpr round(bool distinct = false) const;
    ALDBExpr hex(bool distinct = false) const;
    // ALDBExpr.instr(str) => "INSTR(str, ALDBExpr)"
    ALDBExpr instr(const ALDBExpr &str) const;
    ALDBExpr substr(const ALDBExpr &from) const;
    ALDBExpr substr(const ALDBExpr &from, const ALDBExpr &len) const;
    ALDBExpr replace(const ALDBExpr &find, const ALDBExpr &replacement) const;
    ALDBExpr ltrim() const;
    ALDBExpr ltrim(const ALDBExpr &trim_str) const;
    ALDBExpr rtrim() const;
    ALDBExpr rtrim(const ALDBExpr &trim_str) const;
    ALDBExpr trim() const;
    ALDBExpr trim(const ALDBExpr &trim_str) const;
};
