//
//  column_result.hpp
//  alloy
//
//  Created by Alex Lee on 30/09/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//
//  Fork from WCDB, github: https://github.com/tencent/wcdb
//

#ifndef column_result_hpp
#define column_result_hpp

#include <stdio.h>
#include "sql_clause.hpp"

namespace aldb {

class Expr;
struct SQLValue;

//@link: http://www.sqlite.org/lang_select.html
class ResultColumn : public SQLClause {
  public:
    ResultColumn(const Expr &expr);

    ResultColumn &as(const std::string &alias);

    static ResultColumn any();
    static ResultColumn any(const std::string &tableName);

  protected:
    ResultColumn();
};
}

#endif /* column_result_hpp */
