//
//  result_set.cpp
//  alloy
//
//  Created by Alex Lee on 01/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#include "result_set.hpp"
#include "statement_handle.hpp"
#include <sqlite3.h>

namespace aldb {
    
ResultSet::ResultSet(std::shared_ptr<aldb::StatementHandle> stmt) : _stmt(stmt){};
    
void ResultSet::close() { _stmt->finalize(); }

bool ResultSet::next() { return _stmt->step(); }

const int32_t ResultSet::get_int32_value(int index) {
    return (int32_t) sqlite3_column_int((sqlite3_stmt *) _stmt->_stmt, index);
}

const int64_t ResultSet::get_int64_value(int index) {
    return (int64_t) sqlite3_column_int64((sqlite3_stmt *) _stmt->_stmt, index);
}

const double ResultSet::get_double_value(int index) {
    return (double) sqlite3_column_double((sqlite3_stmt *) _stmt->_stmt, index);
}

const char *ResultSet::get_text_value(int index) {
    return (const char *) sqlite3_column_text((sqlite3_stmt *) _stmt->_stmt, index);
}
    
const void *ResultSet::get_blob_value(int index) {
    return (const void *) sqlite3_column_blob((sqlite3_stmt *) _stmt->_stmt, index);
}

int ResultSet::column_count() const { return sqlite3_column_count((sqlite3_stmt *) _stmt->_stmt); }

const char *ResultSet::column_name(int idx) const { return sqlite3_column_name((sqlite3_stmt *) _stmt->_stmt, idx); }
}
