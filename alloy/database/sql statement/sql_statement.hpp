//
//  sql_statement.hpp
//  alloy
//
//  Created by Alex Lee on 30/09/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//
//  Fork from WCDB, github: https://github.com/tencent/wcdb
//

#ifndef sql_statement_hpp
#define sql_statement_hpp

#include <stdio.h>
#include "sql_clause.hpp"

namespace aldb {
class SQLStatement : public SQLClause {
  public:
    SQLStatement();
    virtual ~SQLStatement();
};
}

#endif /* sql_statement_hpp */
