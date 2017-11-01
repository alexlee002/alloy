//
//  column_def.hpp
//  alloy
//
//  Created by Alex Lee on 30/09/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//
//  Fork from WCDB, github: https://github.com/tencent/wcdb
//

#ifndef column_def_hpp
#define column_def_hpp

#include <stdio.h>
#include <string>
#include "sql_clause.hpp"
#include "defines.hpp"

namespace aldb {
class Expr;
struct SQLValue;
class Column;
    
//@link: http://www.sqlite.org/lang_createtable.html
class ColumnDef : public SQLClause {
  public:
    ColumnDef(const Column &column, ColumnType type);

    ColumnDef &as_primary(OrderBy order = OrderBy::DEFAULT,
                          ConflictPolicy conflict = ConflictPolicy::DEFAULT,
                          bool autoincrement = false);

    ColumnDef &not_null(ConflictPolicy conflict = ConflictPolicy::DEFAULT);
    ColumnDef &as_unique(ConflictPolicy conflict = ConflictPolicy::DEFAULT);
    ColumnDef &check(const Expr &expr);
    ColumnDef &default_value(const SQLValue &value);
    ColumnDef &default_value(const Expr &value);
    ColumnDef &default_value(const std::nullptr_t &value);
    ColumnDef &default_value(DefaultTimeValue time);
    ColumnDef &collate(const std::string &name);
    
public:
    bool is_primary() const;
    bool is_autoincrement() const;
    bool is_unique() const;
    
private:
    bool _primary;
    bool _autoincrement;
    bool _unique;
};
}

#endif /* column_def_hpp */
