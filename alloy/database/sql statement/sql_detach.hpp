//
//  sql_detach.hpp
//  alloy
//
//  Created by Alex Lee on 02/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//
//  Fork from WCDB, github: https://github.com/tencent/wcdb
//

#ifndef sql_detach_hpp
#define sql_detach_hpp

#include "sql_statement.hpp"

namespace aldb {

class SQLDetach : public SQLStatement {
public:
    SQLDetach &detach(const std::string &schema);
};

} //namespace aldb

#endif /* sql_attach_hpp */
