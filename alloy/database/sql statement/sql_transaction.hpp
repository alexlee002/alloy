//
//  sql_transaction.hpp
//  alloy
//
//  Created by Alex Lee on 02/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//
//  Fork from WCDB, github: https://github.com/tencent/wcdb
//

#ifndef sql_transaction_hpp
#define sql_transaction_hpp

#include <stdio.h>
#include "sql_statement.hpp"
#include "defines.hpp"

namespace aldb {
    
//@link: http://www.sqlite.org/lang_transaction.html
class SQLTransaction : public SQLStatement {
  public:
    enum class Action : int { BEGIN, COMMIT, ROLLBACK };

    SQLTransaction &begin(TransactionMode mode = TransactionMode::IMMEDIATE);
    SQLTransaction &commit();
    SQLTransaction &rollback();

    const SQLTransaction::Action action() const;
    
private:
    Action _action;
};
}

#endif /* sql_transaction_hpp */
