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

#define ALDB_SET_REF_VAL(ref_ptr, value) if(ref_ptr) { *ref_ptr = value; }

namespace aldb {

const std::string str_to_upper(const std::string &str);

const std::string to_hex_string(const std::string str);

const std::string literal_value(const std::string &str, bool blob_type = false);
}

#endif /* utils_h */
