//
//  table_constraint.hpp
//  alloy
//
//  Created by Alex Lee on 30/09/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//
//  Fork from WCDB, github: https://github.com/tencent/wcdb
//

#ifndef table_constraint_hpp
#define table_constraint_hpp

#include <stdio.h>
#include "sql_clause.hpp"
#include "defines.hpp"

namespace aldb {
class IndexColumn;
class Expr;

//@link: http://www.sqlite.org/lang_createtable.html
class TableConstraint : public SQLClause {
  public:
    TableConstraint();
    TableConstraint(const std::string &name);

    TableConstraint &primary_key(const std::list<const IndexColumn> &columns,
                                 ConflictPolicy conflict = ConflictPolicy::DEFAULT);

    TableConstraint &unique(const std::list<const IndexColumn> &columns,
                            ConflictPolicy conflict = ConflictPolicy::DEFAULT);

    TableConstraint &check(const Expr &expr);
    
protected:
    void on_conflict(ConflictPolicy conflict);
};
}

#endif /* table_constraint_hpp */
