//
//  qualified_table_name.hpp
//  alloy
//
//  Created by Alex Lee on 01/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#ifndef qualified_table_name_hpp
#define qualified_table_name_hpp

#include <stdio.h>
#include "sql_clause.hpp"

namespace aldb {
class QualifiedTableName : public SQLClause {
  public:
    QualifiedTableName(const std::string &table_name);
    QualifiedTableName(const char *table_name);

    QualifiedTableName &indexed_by(const std::string &index_name);
    QualifiedTableName &not_indexed();
};
}

#endif /* qualified_table_name_hpp */
