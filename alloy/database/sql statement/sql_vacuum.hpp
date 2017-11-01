//
//  sql_vacuum.hpp
//  alloy
//
//  Created by Alex Lee on 02/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//
//  Fork from WCDB, github: https://github.com/tencent/wcdb
//

#ifndef sql_vacuum_hpp
#define sql_vacuum_hpp

#include "sql_statement.hpp"

namespace aldb {

class SQLVacuum : public SQLStatement {
public:
    SQLVacuum &vacuum(const std::string &schemaName = "");

};

} //namespace aldb

#endif /* sql_vacuum_hpp */
