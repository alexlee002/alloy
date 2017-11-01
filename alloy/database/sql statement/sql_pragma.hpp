//
//  sql_pragma.hpp
//  alloy
//
//  Created by Alex Lee on 01/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//
//  Fork from WCDB, github: https://github.com/tencent/wcdb
//

#ifndef sql_pragma_hpp
#define sql_pragma_hpp

#include <stdio.h>
#include "sql_statement.hpp"

namespace aldb {
    class Pragma;
    struct SQLValue;
    
    class SQLPragma : public SQLStatement {
    public:
        SQLPragma &pragma(const Pragma &pragma);
        SQLPragma &pragma(const Pragma &pragma, const SQLValue &value);
    };
}

#endif /* sql_pragma_hpp */
