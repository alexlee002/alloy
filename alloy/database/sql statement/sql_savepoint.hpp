//
//  sql_savepoint.hpp
//  alloy
//
//  Created by Alex Lee on 02/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//
//  Fork from WCDB, github: https://github.com/tencent/wcdb
//

#ifndef sql_savepoint_hpp
#define sql_savepoint_hpp

#include <stdio.h>
#include "sql_statement.hpp"

namespace aldb {

//@link: http://www.sqlite.org/lang_savepoint.html
class SQLSavePoint : public SQLStatement {
  public:
    SQLSavePoint &savepoint(const std::string &name);
    SQLSavePoint &release(const std::string &name);
    SQLSavePoint &rollback(const std::string &name);
};
}

#endif /* sql_savepoint_hpp */
