//
//  column_index.hpp
//  alloy
//
//  Created by Alex Lee on 30/09/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//
//  Fork from WCDB, github: https://github.com/tencent/wcdb
//

#ifndef column_index_hpp
#define column_index_hpp

#include <stdio.h>
#include "sql_clause.hpp"
#include "defines.hpp"

namespace aldb {

class Expr;
struct SQLValue;
class Column;

/*!
 * @link: http://www.sqlite.org/lang_createindex.html
 */
class IndexColumn : public SQLClause {
  public:
    IndexColumn(const Column &column, const std::string &collate = BinaryCollate, OrderBy order = OrderBy::DEFAULT);
    IndexColumn(const Expr &expr, const std::string &collate = BinaryCollate, OrderBy term = OrderBy::DEFAULT);
    
    operator std::list<const IndexColumn>() const;
};
}

#endif /* column_index_hpp */
