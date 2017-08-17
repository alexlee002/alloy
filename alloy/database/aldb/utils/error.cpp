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

Error::operator std::string() const { return "Error: [" + domain + ": " + std::to_string(code) + "]; " + message; }

void Error::log(const char *file, int line) const {
    printf("‼️ [ALDB] - ");
    if (file && strlen(file) > 0) {
        printf("(%s: %d)", basename((char *) file), line);
    }
    printf("%s\n", std::string(*this).c_str());
}
}
