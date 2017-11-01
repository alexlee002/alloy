//
//  sql_attach.hpp
//  alloy
//
//  Created by Alex Lee on 02/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//
//  Fork from WCDB, github: https://github.com/tencent/wcdb
//

#ifndef sql_attach_hpp
#define sql_attach_hpp

#include "sql_statement.hpp"

namespace aldb {
    
class Expr;

class SQLAttach : public SQLStatement {
public:
    SQLAttach &attach(const Expr &expr);
    SQLAttach &as(const std::string &schema);
};

} //namespace aldb

#endif /* sql_attach_hpp */
