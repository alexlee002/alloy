//
//  utils.cpp
//  alloy
//
//  Created by Alex Lee on 01/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#include "utils.hpp"
#include "defines.hpp"

namespace aldb {
    
std::string str_to_upper(const std::string &str) {
    std::string upper(str);
    std::transform(upper.begin(), upper.end(), upper.begin(), std::toupper);
    return upper;
}

std::string to_hex_string(const void *bytes, size_t len) {
    static const char *hex_chars = "0123456789abcdef";

    if (!bytes || len == 0) {
        return "";
    }

    char result[len * 2 + 1];
    char *dp = result;
    char *sp = reinterpret_cast<char *>(const_cast<void *>(bytes));
    for (size_t i = 0; i < len; ++i) {
        (*dp++) = hex_chars[((*sp & 0xF0) >> 4)];
        (*dp++) = hex_chars[(*sp & 0x0F)];
        sp++;
    }
    *dp = '\0';
    return std::string(result);
}

static inline std::string string_replace(const std::string &origin,
                                         const std::string &match,
                                         const std::string &replacement) {
    bool replace = false;
    size_t last  = 0;
    size_t found = 0;
    std::string output;
    while ((found = origin.find(match, last)) != std::string::npos) {
        if (!replace) {
            replace = true;
            output.clear();
        }
        std::string sub = origin.substr(last, found - last);
        output += sub;
        output += replacement;
        last = found + match.length();
    }
    if (replace) {
        output += origin.substr(last, -1);
    }
    return replace ? output : origin;
}

std::string literal_text(const std::string &str) {
    return "'" + string_replace(str, "'", "''") + "'";
}

std::string literal_blob(const void *bytes, size_t len) {
    return "X'" + to_hex_string(bytes, len) + "'";
}

std::shared_ptr<Error> sqlite_error(sqlite3 *h, const char *sql) {
    std::string errmsg;
    if (sql) {
        errmsg.append("sql: \"" + std::string(sql) + "\"; ");
    }
    const char *sqlite_err = sqlite3_errmsg(h);
    if (sqlite_err) {
        errmsg.append(sqlite_err);
    }
    return std::shared_ptr<Error>(new Error(aldb::SqliteErrorDomain, sqlite3_errcode(h), errmsg.c_str()));
}

std::shared_ptr<Error> aldb_error(int code, const char *message) {
    return std::shared_ptr<Error>(new Error(aldb::ALDBErrorDomain, code, message));
}
}
