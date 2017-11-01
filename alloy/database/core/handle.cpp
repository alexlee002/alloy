//
//  handle.cpp
//  alloy
//
//  Created by Alex Lee on 22/07/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#include <sqlite3.h>
#include "handle.hpp"
#include "sql_value.hpp"
#include "statement_handle.hpp"
#include "error.hpp"
#include "utils.hpp"
#include "macros.h"

namespace aldb {
Handle::Handle(const std::string &path) : aldb::Catchable(), _path(path), _handle(nullptr), _cache_stmt(false) {
}

Handle::~Handle() {
    close();
}

const std::string &Handle::get_path() const {
    return _path;
}

void Handle::cache_statement_for_sql(const std::string &sql) {
    auto it = _stmt_caches.find(sql);
    if (it == _stmt_caches.end()) {
        _stmt_caches.insert({sql, nullptr});
    }
}

bool Handle::open() {
    if (_handle) {
        Catchable::reset_error();
        return true;
    }

    int rc =
        sqlite3_open_v2(_path.c_str(), (sqlite3 **) &_handle, (SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE), nullptr);
    if (rc == SQLITE_OK) {
        Catchable::reset_error();
        return true;
    }

    Catchable::set_sqlite_error((sqlite3 *) _handle);
    _handle = nullptr;
    return false;
}

void Handle::close() {
    // TODO: close statements & resultsets
    for (auto it = _stmt_caches.begin(); it != _stmt_caches.end(); ++it) {
        auto stmt = it->second;
        stmt->_cached = false;
        stmt->finalize();
    }

    if (!_handle) {
        return;
    }

    int rc;
    bool retry = false, tryFinalizingOpenedStatements = false;
    do {
        retry = false;
        rc = sqlite3_close((sqlite3 *) _handle);
        if (SQLITE_BUSY == rc || SQLITE_LOCKED == rc) {
            if (!tryFinalizingOpenedStatements) {
                tryFinalizingOpenedStatements = true;
                sqlite3_stmt *pstmt;
                while ((pstmt = sqlite3_next_stmt((sqlite3 *) _handle, nullptr)) != 0) {
                    // Closing leaked statement;
                    sqlite3_finalize(pstmt);
                    retry = true;
                }
            }
        } else if (SQLITE_OK != rc) {
            ALDB_ERROR(aldb::sqlite_error((sqlite3 *)_handle)->description().c_str());
        }
    } while (retry);

    _handle = nullptr;
}

std::shared_ptr<StatementHandle> Handle::prepare(const std::string &sql) {
    bool need_cache_stmt = false;

    auto it = _stmt_caches.find(sql);
    if (it != _stmt_caches.end()) {
        std::shared_ptr<StatementHandle> cached_stmt = it->second;
        if (cached_stmt) {
            if (!cached_stmt->_inuse) {
                cached_stmt->reset_bindings();
                cached_stmt->_cached = true;
                cached_stmt->_inuse  = true;
                cached_stmt->threadid = __ALDB_CURRENT_THREAD_ID();
                ALDB_DEBUG("handle: %p re-use stmt: %p\n", this, cached_stmt.get());
                return cached_stmt;
            }
        } else {
            need_cache_stmt = true;
        }
    }

    sqlite3_stmt *pstmt = nullptr;
    int rc = sqlite3_prepare_v2((sqlite3 *) _handle, sql.c_str(), -1, &pstmt, nullptr);
    if (SQLITE_OK != rc) {
        Catchable::set_sqlite_error((sqlite3 *) _handle, sql.c_str());
        sqlite3_finalize(pstmt);
        return nullptr;
    }

    Catchable::reset_error();
    auto stmt = std::shared_ptr<StatementHandle>(new StatementHandle(*this, pstmt));
    if (need_cache_stmt) {
        _stmt_caches.erase(sql);
        _stmt_caches.insert({sql, stmt});
        stmt->_cached = true;
    }
    stmt->_inuse = true;
    stmt->threadid = __ALDB_CURRENT_THREAD_ID();

    return stmt;
}

bool Handle::exec(const std::string &sql) {
    int rc = sqlite3_exec((sqlite3 *) _handle, sql.c_str(), nullptr, nullptr, nullptr);
    if (SQLITE_OK == rc) {
        Catchable::reset_error();
        return true;
    }
    
    Catchable::set_sqlite_error((sqlite3 *)_handle, sql.c_str());
    return false;
}

bool Handle::exec(const std::string &sql, const std::list<const aldb::SQLValue> &args) {
    std::shared_ptr<StatementHandle> stmt = prepare(sql);
    if (!stmt) {
        return false;
    }
    int idx = 1;
    for (const SQLValue &v : args) {
        stmt->bind_value(v, idx);
        idx++;
    }
    
    stmt->step();
    Catchable::retain_error(stmt->get_error());
    stmt->finalize();
    
    return !Catchable::has_error();
}

int64_t Handle::last_inserted_rowid() {
    return sqlite3_last_insert_rowid((sqlite3 *) _handle);
}

void Handle::register_wal_commited_hook(int (*hook)(aldb::Handle *, sqlite3 *, const char *, int /*pages*/), void *info) {
    if (hook) {
        sqlite3_wal_hook((sqlite3 *) _handle, (int (*)(void *, sqlite3 *, const char *, int)) hook, this);
    } else {
        sqlite3_wal_hook((sqlite3 *) _handle, nullptr, nullptr);
    }
}

void Handle::register_custom_sql_function(const std::string &name, int argc, void (*func)(void *, int, void **)) {
    if (!name.empty() && func) {
        sqlite3_create_function((sqlite3 *) _handle, name.c_str(), argc, SQLITE_UTF8, nullptr,
                                (void (*)(sqlite3_context *, int, sqlite3_value **)) func, nullptr, nullptr);
    }
}

void Handle::register_sqlite_busy_handler(int (*busy_handler)(void *, int)) {
    if (busy_handler) {
        sqlite3_busy_handler((sqlite3 *) _handle, (int (*)(void *, int)) busy_handler, this);
    } else {
        sqlite3_busy_handler((sqlite3 *) _handle, nullptr, nullptr);
    }
}

int Handle::get_changes() const {
    return sqlite3_changes((sqlite3 *) _handle);
}
}
