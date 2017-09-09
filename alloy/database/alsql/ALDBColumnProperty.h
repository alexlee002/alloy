//
//  ALDBColumnProperty.h
//  alloy
//
//  Created by Alex Lee on 21/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <string>
#import "ALSQLExpr.h"
#import "ALDBColumn.h"
#import "ALPropertyColumnBindings.h"

class ALDBColumnProperty : public ALDBColumn {
  public:
//    ALDBColumnProperty(const ALDBColumnProperty &o);
    ALDBColumnProperty();
    ALDBColumnProperty(ALPropertyColumnBindings *propertyColumnBidings);
//    ALDBColumnProperty(const std::string &columnName, ALPropertyColumnBindings *propertyColumnBidings);
    ALDBColumnProperty(const ALDBColumn &column, ALPropertyColumnBindings *propertyColumnBidings);

    //    ALDBColumnProperty distinct() const;
    ALDBColumnProperty in_table(NSString *tableName) const;

    //    ALDBColumnProperty desc() const;
    //    ALDBColumnProperty asc() const;
    const std::string name() const;
    id column_binding() const;
    Class binding_class() const;

#pragma mark - operations
    // unary
    ALSQLExpr operator!() const;
    ALSQLExpr operator+() const;
    ALSQLExpr operator-() const;
    ALSQLExpr operator~() const;

    // binary
    ALSQLExpr operator||(const ALSQLExpr &r) const;  // or, not concat
    ALSQLExpr operator&&(const ALSQLExpr &r) const;
    ALSQLExpr operator*(const ALSQLExpr &r) const;
    ALSQLExpr operator/(const ALSQLExpr &r) const;
    ALSQLExpr operator%(const ALSQLExpr &r) const;
    ALSQLExpr operator+(const ALSQLExpr &r) const;
    ALSQLExpr operator-(const ALSQLExpr &r) const;
    ALSQLExpr operator<<(const ALSQLExpr &r) const;
    ALSQLExpr operator>>(const ALSQLExpr &r) const;
    ALSQLExpr operator&(const ALSQLExpr &r) const;
    ALSQLExpr operator|(const ALSQLExpr &r) const;
    ALSQLExpr operator<(const ALSQLExpr &r) const;
    ALSQLExpr operator<=(const ALSQLExpr &r) const;
    ALSQLExpr operator>(const ALSQLExpr &r) const;
    ALSQLExpr operator>=(const ALSQLExpr &r) const;
    ALSQLExpr operator==(const ALSQLExpr &r) const;
    ALSQLExpr operator!=(const ALSQLExpr &r) const;

    ALSQLExpr in(const std::list<const ALSQLExpr> &expr_list) const;
    ALSQLExpr in(const std::string &table_name) const;
    //    ALSQLExpr in(const SelectStatement &stmt) const;
    ALSQLExpr not_in(const std::list<const ALSQLExpr> &expr_list) const;
    ALSQLExpr not_in(const std::string &table_name) const;
    //    ALSQLExpr not_in(const char *table_name) const;

    ALSQLExpr like(const ALSQLExpr &expr, const ALSQLExpr &escape = ALSQLExpr::s_null_expr) const;
    ALSQLExpr not_like(const ALSQLExpr &expr, const ALSQLExpr &escape = ALSQLExpr::s_null_expr) const;

    ALSQLExpr is_null() const;
    ALSQLExpr not_null() const;
    ALSQLExpr is(const ALSQLExpr &expr) const;
    ALSQLExpr is_not(const ALSQLExpr &expr) const;

    ALSQLExpr cast_as(const std::string &type_name);
    ALSQLExpr cast_as(const ALDBColumnType type);
    //    static ALSQLExpr exists(const SelectStatement &stmt);
    //    static ALSQLExpr not_exists(const SelectStatement &stmt);

    // case (*this) when b then c else d end
    ALSQLExpr case_when(const std::list<const std::pair<const ALSQLExpr, const ALSQLExpr>> &when_then,
                        const ALSQLExpr &else_value = ALSQLExpr::s_null_expr);

#pragma mark - sql functions
    //@link: http://www.sqlite.org/lang_corefunc.html

    ALSQLExpr function(const std::string &name, bool distinct = false);
    ALSQLExpr concat(const ALSQLExpr &expr) const;  // "abc"||"def"
    ALSQLExpr abs() const;
    ALSQLExpr length() const;
    ALSQLExpr lower() const;
    ALSQLExpr upper() const;
    // expr.instr(str) => "INSTR(str, expr)"
    ALSQLExpr instr(const ALSQLExpr &str) const;
    ALSQLExpr substr(const ALSQLExpr &from) const;
    ALSQLExpr substr(const ALSQLExpr &from, const ALSQLExpr &len) const;
    ALSQLExpr replace(const ALSQLExpr &find, const ALSQLExpr &replacement) const;
    ALSQLExpr ltrim() const;
    ALSQLExpr ltrim(const ALSQLExpr &trim_str) const;
    ALSQLExpr rtrim() const;
    ALSQLExpr rtrim(const ALSQLExpr &trim_str) const;
    ALSQLExpr trim() const;
    ALSQLExpr trim(const ALSQLExpr &trim_str) const;
    ALSQLExpr avg(bool distinct = false) const;
    ALSQLExpr count(bool distinct = false) const;
    ALSQLExpr group_concat(bool distinct = false) const;
    ALSQLExpr group_concat(const ALSQLExpr &seperator, bool distinct = false) const;
    ALSQLExpr max(bool distinct = false) const;
    ALSQLExpr min(bool distinct = false) const;
    ALSQLExpr sum(bool distinct = false) const;
    ALSQLExpr total(bool distinct = false) const;

  private:
    ALPropertyColumnBindings *_binding;
};
