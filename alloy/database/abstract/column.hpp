//
//  column.hpp
//  alloy
//
//  Created by Alex Lee on 30/09/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//
//  Fork from WCDB, github: https://github.com/tencent/wcdb
//

#ifndef column_hpp
#define column_hpp

#include <stdio.h>
#include <string>
#include <list>
#include "sql_clause.hpp"

namespace aldb {
class Column: public SQLClause {
  public:
    static const Column ANY;
    static const Column ROWID;
    
    Column();
    Column(const char *name);
    Column(const std::string &name);
    
    explicit operator const std::string &() const;
    const std::string &name() const;
    Column in_table(const std::string &table) const;

    operator std::list<Column>() const;
    bool operator==(const Column &column) const;
};
}

#endif /* column_hpp */
