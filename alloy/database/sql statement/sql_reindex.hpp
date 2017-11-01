//
//  sql_reindex.hpp
//  alloy
//
//  Created by Alex Lee on 01/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//
//  Fork from WCDB, github: https://github.com/tencent/wcdb
//

#ifndef sql_reindex_hpp
#define sql_reindex_hpp

#include <stdio.h>
#include "sql_statement.hpp"

namespace aldb {
//@link: http://www.sqlite.org/lang_reindex.html
class SQLReindex : public SQLStatement {
    SQLReindex &reindex(const std::string &name);
};
}

#endif /* sql_reindex_hpp */
