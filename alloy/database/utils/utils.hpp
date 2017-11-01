//
//  utils.h
//  alloy
//
//  Created by Alex Lee on 01/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#ifndef utils_h
#define utils_h

#include <string>
#include <list>
#include <functional>
#include <sqlite3.h>
#include "error.hpp"


#define ALDB_SET_REF_VAL(ref_ptr, value) if(ref_ptr) { *ref_ptr = value; }

namespace aldb {

std::string str_to_upper(const std::string &str);

std::string to_hex_string(const void *bytes, size_t len);

std::string literal_text(const std::string &str);
std::string literal_blob(const void *bytes, size_t len);

template <typename T, typename U>
std::list<const T> list_map(const std::list<const U> &from_list) {
    std::list<const T> to_list;
    for (auto u : from_list) {
        to_list.push_back(T(u));
    }
    return to_list;
}

template <typename T, typename U>
std::list<T> list_map(const std::list<U> &src, std::function<T(U &)> map_func) {
    std::list<T> dest;
    for (auto u : src) {
        dest.push_back(map_func(u));
    }
    return dest;
}

std::shared_ptr<Error> sqlite_error(sqlite3 *h, const char *sql = NULL);
std::shared_ptr<Error> aldb_error(int code, const char *message);
}

#endif /* utils_h */
