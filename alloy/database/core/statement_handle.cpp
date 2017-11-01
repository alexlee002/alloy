//
//  statement_handle.cpp
//  alloy
//
//  Created by Alex Lee on 23/07/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#include "statement_handle.hpp"
#include "sql_value.hpp"
#include "handle.hpp"
#include "Error.hpp"
#include "defines.hpp"
#include "macros.h"
#include <assert.h>
#include <pthread.h>
#include <sqlite3.h>

namespace aldb {
StatementHandle::StatementHandle(const Handle &handle, void *stmt)
    : aldb::Catchable()
    , _hadler(handle)
    , _stmt(stmt)
    , _inuse(false)
    , _cached(false) {}
    
StatementHandle::~StatementHandle() { finalize(); }

void StatementHandle::finalize() {
    // if this statement is cached by Handle, need to unset _cached flag to finalize
    if (_cached) {
        _inuse   = false;
        threadid = 0;
        return;
    }

    if (!_stmt) {
        return;
    }

    sqlite3 *h = sqlite3_db_handle((sqlite3_stmt *) _stmt);
    int rc     = sqlite3_finalize((sqlite3_stmt *) _stmt);
    _stmt      = nullptr;
    if (rc == SQLITE_OK) {
        Catchable::reset_error();
        _inuse = false;
        return;
    }
    Catchable::set_sqlite_error(h);
    Catchable::log_error(__FILE__, __LINE__);
}

int StatementHandle::step() {
    __ALDB_CHECK_THREAD(this->threadid);

    int rc = sqlite3_step((sqlite3_stmt *) _stmt);
    if (rc == SQLITE_ROW || rc == SQLITE_OK || rc == SQLITE_DONE) {
        Catchable::reset_error();
    } else {
        Catchable::set_sqlite_error(sqlite3_db_handle((sqlite3_stmt *) _stmt));
        Catchable::log_error(__FILE__, __LINE__);
    }
    return rc;
}

bool StatementHandle::next_row() {
    if (!_stmt) {
        return false;
    }

    int rc = step();
#if DEBUG
    if (SQLITE_OK == rc) {
        // should use exec() instead
    }
#endif

    return SQLITE_ROW == rc;
}

bool StatementHandle::exec() {
    if (!_stmt) {
        return false;
    }

    int rc = step();
#if DEBUG
    if (SQLITE_ROW == rc || SQLITE_DONE == rc) {
        // should use query() insted
    }
#endif
    return SQLITE_OK == rc || SQLITE_ROW == rc || SQLITE_DONE == rc;
}

bool StatementHandle::reset_bindings() {
    if (!_stmt) {
        // TODO: assert?
        return false;
    }
    int rc = sqlite3_reset((sqlite3_stmt *) _stmt);
    if (rc == SQLITE_OK) {
        Catchable::reset_error();
        return true;
    } else {
        Catchable::set_sqlite_error(sqlite3_db_handle((sqlite3_stmt *) _stmt));
        Catchable::log_error(__FILE__, __LINE__);
        return false;
    }
}

bool StatementHandle::bind_value(const SQLValue &value, const int index) {
    int rc = SQLITE_OK;
    switch (value.val_type) {
        case aldb::ColumnType::INT32_T:
            rc = sqlite3_bind_int((sqlite3_stmt *) _stmt, index, value.i32_val);
            break;
        case aldb::ColumnType::INT64_T:
            rc = sqlite3_bind_int64((sqlite3_stmt *) _stmt, index, value.i64_val);
            break;
        case aldb::ColumnType::DOUBLE_T:
            rc = sqlite3_bind_double((sqlite3_stmt *) _stmt, index, value.d_val);
            break;
        case aldb::ColumnType::TEXT_T:
            rc = sqlite3_bind_text((sqlite3_stmt *) _stmt, index, value.s_val.c_str(), -1, SQLITE_TRANSIENT);
            break;
        case aldb::ColumnType::BLOB_T:
            rc = sqlite3_bind_blob((sqlite3_stmt *) _stmt, index, value.s_val.data(), (int) value.s_val.size(),
                                   SQLITE_TRANSIENT);
            break;
        case aldb::ColumnType::NULL_T:
            rc = sqlite3_bind_null((sqlite3_stmt *) _stmt, index);
            break;

        default:
            rc = sqlite3_bind_blob((sqlite3_stmt *) _stmt, index, std::string(value).c_str(), -1, SQLITE_STATIC);
            break;
    }
    if (rc != SQLITE_OK) {
        Catchable::set_sqlite_error(sqlite3_db_handle((sqlite3_stmt *) _stmt));
        Catchable::log_error(__FILE__, __LINE__);
        return false;
    } else {
        Catchable::reset_error();
        return true;
    }
}

const int32_t StatementHandle::get_int32_value(int index) const {
    return (int32_t) sqlite3_column_int((sqlite3_stmt *) _stmt, index);
}

const int64_t StatementHandle::get_int64_value(int index) const {
    return (int64_t) sqlite3_column_int64((sqlite3_stmt *) _stmt, index);
}

const double StatementHandle::get_double_value(int index) const {
    return (double) sqlite3_column_double((sqlite3_stmt *) _stmt, index);
}

const char *StatementHandle::get_text_value(int index) const {
    return (const char *) sqlite3_column_text((sqlite3_stmt *) _stmt, index);
}

const void *StatementHandle::get_blob_value(int index, size_t &size) const {
    size = sqlite3_column_bytes((sqlite3_stmt *) _stmt, index);
    return (const void *) sqlite3_column_blob((sqlite3_stmt *) _stmt, index);
}

int64_t StatementHandle::last_insert_rowid() const {
    return sqlite3_last_insert_rowid(sqlite3_db_handle((sqlite3_stmt *) _stmt));
}

int StatementHandle::changes() const {
    return _hadler.get_changes();
}

int StatementHandle::column_count() const {
    return sqlite3_column_count((sqlite3_stmt *) _stmt);
}

const char *StatementHandle::column_name(int idx) const {
    return sqlite3_column_name((sqlite3_stmt *) _stmt, idx);
}

int StatementHandle::column_index(const char *name) {
    if (!_column_names_map) {
        std::shared_ptr<std::unordered_map<std::string, int>> index_map(new std::unordered_map<std::string, int>());
        for (int i = 0; i < column_count(); ++i) {
            index_map->insert({column_name(i), i});
        }
        _column_names_map = index_map;
    }

    auto it = _column_names_map->find(name);
    if (it != _column_names_map->end()) {
        return it->second;
    }
    return -1;
}

ColumnType StatementHandle::column_type(int idx) const {
    int type = sqlite3_column_type((sqlite3_stmt *) _stmt, idx);
    switch (type) {
        case SQLITE_INTEGER:
            return ColumnType::INT64_T;
        case SQLITE_FLOAT:
            return ColumnType::DOUBLE_T;
        case SQLITE_BLOB:
            return ColumnType::BLOB_T;
        case SQLITE_NULL:
            return ColumnType::NULL_T;
        case SQLITE_TEXT:
            return ColumnType::TEXT_T;

        default:
            return ColumnType::BLOB_T;
    }
}

const char *StatementHandle::sql() const {
    return sqlite3_sql((sqlite3_stmt *) _stmt);
}

const char *StatementHandle::expanded_sql() const {
    return sqlite3_expanded_sql((sqlite3_stmt *) _stmt);
}
}
