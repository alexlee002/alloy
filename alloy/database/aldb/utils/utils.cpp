//
//  utils.cpp
//  alloy
//
//  Created by Alex Lee on 01/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#include "utils.hpp"

namespace aldb {
const std::string str_to_upper(const std::string &str) {
    std::string upper(str);
    std::transform(upper.begin(), upper.end(), upper.begin(), std::toupper);
    return upper;
}

const std::string to_hex_string(const std::string str) {
    std::string hex_str;
    const char *hex_chars = "0123456789abcdef";
    for (auto c : str) {
        hex_str.append(1, hex_chars[((c & 0xF0) >> 4)]);
        hex_str.append(1, hex_chars[(c & 0x0F)]);
    }
    return hex_str;
}

const std::string literal_value(const std::string &str, bool blob_type) {
    if (blob_type) {
        return "X'" + to_hex_string(str) + "'";
    } else {
        // TODO: need to escape '
        return "'" + str + "'";
    }
}
}
