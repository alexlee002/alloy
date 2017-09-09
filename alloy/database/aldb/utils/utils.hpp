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

#define ALDB_SET_REF_VAL(ref_ptr, value) if(ref_ptr) { *ref_ptr = value; }

namespace aldb {

const std::string str_to_upper(const std::string &str);

const std::string to_hex_string(const std::string str);

const std::string literal_value(const std::string &str, bool blob_type = false);

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
}

#endif /* utils_h */
