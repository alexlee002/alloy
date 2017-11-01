//
//  catchable.cpp
//  alloy
//
//  Created by Alex Lee on 01/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#include "catchable.hpp"
#include "defines.hpp"
#include "console_logger.hpp"

namespace aldb {

Catchable::Catchable() {
    _error = nullptr;
}

std::shared_ptr<aldb::Error> Catchable::get_error() const {
    return _error;
}

bool Catchable::has_error() const {
    return _error != nullptr;
}

void Catchable::log_error(const char *file, int line) const {
#if DEBUG
    if (_error) {
        aldb::ConsoleLogger::write(file, line, NULL, "ALDB", aldb::ConsoleLogger::Level::ERROR,
                                   _error->description().c_str());
    }
#endif
}

void Catchable::reset_error() {
    _error = nullptr;
}

void Catchable::set_error(const Error &error) {
    _error = std::shared_ptr<Error>(new Error(error));
}

void Catchable::retain_error(const std::shared_ptr<Error> error) {
    _error = error;
}

void Catchable::set_sqlite_error(sqlite3 *h, const char *sql) {
    std::string errmsg;
    if (sql) {
        errmsg.append("sql: \"" + std::string(sql) + "\"; ");
    }
    const char *sqlite_err = sqlite3_errmsg(h);
    if (sqlite_err) {
        errmsg.append(sqlite_err);
    }
    _error = std::shared_ptr<Error>(new Error(aldb::SqliteErrorDomain, sqlite3_errcode(h), errmsg.c_str()));
}

void Catchable::set_aldb_error(int code, const char *message) {
    _error = std::shared_ptr<Error>(new Error(aldb::ALDBErrorDomain, code, message));
}
}
