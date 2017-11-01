//
//  sql_drop_table.hpp
//  alloy
//
//  Created by Alex Lee on 01/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//
//  Fork from WCDB, github: https://github.com/tencent/wcdb
//

#ifndef sql_drop_hpp
#define sql_drop_hpp

#include <stdio.h>
#include "sql_statement.hpp"

namespace aldb {
class SQLDropTable : public SQLStatement {
  public:
    SQLDropTable &drop(const std::string &table, bool if_exists = true);
};

class SQLDropIndex : public SQLStatement {
  public:
    SQLDropIndex &drop(const std::string &index, bool if_exists = true);
};

class SQLDropTrigger : public SQLStatement {
  public:
    SQLDropTrigger &drop(const std::string &trigger, bool if_exists = true);
};

class SQLDropView : public SQLStatement {
  public:
    SQLDropView &drop(const std::string &view, bool if_exists = true);
};
}

#endif /* sql_drop_hpp */
