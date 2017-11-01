//
//  sql_alter_table.hpp
//  alloy
//
//  Created by Alex Lee on 01/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//
//  Fork from WCDB, github: https://github.com/tencent/wcdb
//

#ifndef sql_alter_table_hpp
#define sql_alter_table_hpp

#include <stdio.h>
#include "sql_statement.hpp"

namespace aldb {
class ColumnDef;

//@link: http://www.sqlite.org/lang_altertable.html
class SQLAlterTable : public SQLStatement {
  public:
    SQLAlterTable &alter(const std::string &table);
    SQLAlterTable &rename(const std::string &new_name);
    SQLAlterTable &add_column(const ColumnDef &column);
};
}

#endif /* sql_alter_table_hpp */
