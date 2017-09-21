//
//  error.cpp
//  aldb-test
//
//  Created by Alex Lee on 11/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#include "error.hpp"
#include <libgen.h>

namespace aldb {

Error::Error(const std::string &domain, int64_t code, const char *message)
    : domain(domain), code(code), message(message){};

Error::Error(const Error &other) : domain(other.domain), code(other.code), message(other.message) {}

Error::operator std::string() const {
    std::string msg;
    msg.append("Error: [" + domain + ": " + std::to_string(code) + "]; " + message);
    if (!file.empty()) {
        msg.append("; First occur in:\"");
        msg.append(std::string(basename((char *)file.c_str())) + ": "+ std::to_string(line) +"\"");
    }
    msg.append("\n");
    return msg;
}

const std::string Error::description() const { return std::string(*this); }

void Error::log(const char *file, int line) const {
    printf("‼️ [ALDB] - ");
    if (file && strlen(file) > 0) {
        printf("(%s: %d)", basename((char *) file), line);
    }
    printf("%s\n", description().c_str());
}

//ErrorPtr::ErrorPtr(): _error(nullptr), _is_null(false){};
//ErrorPtr::ErrorPtr(const Error &error) : _error(std::make_shared<Error>(error)), _is_null(false) {}
//ErrorPtr::ErrorPtr(const std::nullptr_t &) : _error(nullptr), _is_null(true) {}
//ErrorPtr::~ErrorPtr() { _error = nullptr; }
//
//void ErrorPtr::set_error(const Error &err) { _error = std::make_shared<Error>(err); }
//
//ErrorPtr::operator bool() const { return _error != nullptr; }
//
//bool ErrorPtr::operator==(const std::nullptr_t &) const { return _error == nullptr; }
//
//bool ErrorPtr::operator!=(const std::nullptr_t &) const { return _error != nullptr; }
//
//ErrorPtr &ErrorPtr::operator=(const std::nullptr_t &) {
//    _error = nullptr;
//    _is_null = true;
//    return *this;
//}
//
//ErrorPtr &ErrorPtr::operator=(std::shared_ptr<Error> ptr) {
//    _error = ptr;
//    _is_null = !ptr;
//    return *this;
//}
//
//bool ErrorPtr::is_nullptr() const { return !_error && !_is_null; }

}
