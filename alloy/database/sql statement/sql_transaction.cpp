
//
//  sql_transaction.cpp
//  alloy
//
//  Created by Alex Lee on 02/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#include "sql_transaction.hpp"

namespace aldb {
SQLTransaction &SQLTransaction::begin(TransactionMode mode) {
    SQLClause::reset().append("BEGIN");
    switch (mode) {
        case TransactionMode::IMMEDIATE:
            SQLClause::append(" IMMEDIATE");
            break;
        case TransactionMode::EXCLUSIVE:
            SQLClause::append(" EXCLUSIVE");
        default:
            break;
    }

    _action = Action::BEGIN;
    return *this;
}

SQLTransaction &SQLTransaction::commit() {
    SQLClause::reset().append("COMMIT");
    _action = Action::COMMIT;
    return *this;
}

SQLTransaction &SQLTransaction::rollback() {
    SQLClause::reset().append("ROLLBACK");
    _action = Action::COMMIT;
    return *this;
}

const SQLTransaction::Action SQLTransaction::action() const { return _action; }

}
