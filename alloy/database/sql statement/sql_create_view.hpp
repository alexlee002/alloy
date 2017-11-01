//
//  sql_create_view.hpp
//  alloy
//
//  Created by Alex Lee on 02/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//
//  Fork from WCDB, github: https://github.com/tencent/wcdb
//

#ifndef sql_create_view_hpp
#define sql_create_view_hpp

#include <stdio.h>
#include "sql_statement.hpp"

namespace aldb {
class SQLSelect;

//@link: http://www.sqlite.org/lang_createview.html
class SQLCreateView : public SQLStatement {
  public:
    SQLCreateView &create(const std::string &name, bool temporary = false, bool if_not_exists = true);
    SQLCreateView &columns(const std::list<std::string> &column_names);
    SQLCreateView &as(const SQLSelect &select);
};
}

#endif /* sql_create_view_hpp */
