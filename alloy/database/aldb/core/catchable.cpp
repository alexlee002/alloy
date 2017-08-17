//
//  catchable.cpp
//  alloy
//
//  Created by Alex Lee on 01/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#include "catchable.hpp"
#include "defines.hpp"

namespace aldb {
    
Catchable::Catchable() {_error = nullptr; }

std::shared_ptr<aldb::Error> Catchable::get_error() const { return _error; }

bool Catchable::has_error() const { return _error != nullptr; }

void Catchable::log_error(const char *file, int line) const {
    if (_error) {
        _error->log(file, line);
    }
}

void Catchable::reset_error() { _error = nullptr; }

void Catchable::set_error(const Error &error) {
    _error = std::shared_ptr<Error>(new Error(error));
}
    
void Catchable::raise_error(const std::shared_ptr<Error> error) {
    _error = error;
}

void Catchable::set_sqlite_error(sqlite3 *h) {
    _error = std::shared_ptr<Error>(new Error(aldb::SqliteErrorDomain, sqlite3_errcode(h), sqlite3_errmsg(h)));
}

void Catchable::set_aldb_error(int code, const char *message) {
    _error = std::shared_ptr<Error>(new Error(aldb::ALDBErrorDomain, code, message));
}
}
