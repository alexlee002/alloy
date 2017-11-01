//
//  ALDBProperty.h
//  alloy
//
//  Created by Alex Lee on 07/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//
//  Fork from WCDB, github: https://github.com/tencent/wcdb
//

#import <Foundation/Foundation.h>
#import "column.hpp"
#import "expr.hpp"
#import "ALDBCodingMacros_Private.h"
#import "ALDBTypeDefines.h"

class ALDBResultColumnList;
class ALDBExpr;
class SQLSelect;
class ALDBProperty : public aldb::Column {
    __ALDB_PROPERTY_BASE_DEF;

  public:
    ALDBProperty(const char *columnName = "");
    ALDBProperty(NSString *columnName);
    ALDBProperty(const aldb::Column &column);
    ALDBProperty(ALDBColumnBinding *columnBinding);
    ALDBProperty(const char *columnName, Class modelCls, ALDBColumnBinding *columnBinding);
    
    ALDBResultColumnList distinct() const;
    ALDBProperty inTable(NSString *table) const;
    ALDBOrderBy order(ALDBOrder order = ALDBOrderDefault) const;
    ALDBIndex index(ALDBOrder order = ALDBOrderDefault) const;

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
    
#pragma mark - sql functions

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

  protected:
    ALDBProperty(const aldb::Column &column, Class modelCls, ALDBColumnBinding *columnBinding);
};

class ALDBPropertyList : public std::list<const ALDBProperty> {
  public:
    ALDBPropertyList();
    ALDBPropertyList(const ALDBProperty &property);
    ALDBPropertyList(std::initializer_list<const ALDBProperty> list);

    ALDBPropertyList inTable(NSString *tableName) const;
};
