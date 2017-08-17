//
//  defines.hpp
//  alloy
//
//  Created by Alex Lee on 14/07/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#ifndef defines_hpp
#define defines_hpp

#include <stdio.h>
#include <string>

namespace aldb {
    extern const std::string SqliteErrorDomain;
    extern const std::string ALDBErrorDomain;
    
    enum class ColumnType : int8_t { NULL_T, INT32_T, INT64_T, DOUBLE_T, TEXT_T, BLOB_T };
    const std::string column_type_name(const ColumnType type);
    ColumnType column_type_for_name(const std::string &name);
    
    enum class OrderBy: int8_t {DEFAULT, ASC, DESC};
    const std::string order_term (const OrderBy order);
    
    enum class ConflictPolicy: int8_t {DEFAULT, REPLACE, ROLLBACK, ABORT, FAIL, IGNORE};
    const std::string conflict_term(const ConflictPolicy policy);
    
    enum class TransactionMode: int8_t {DEFERED, IMMEDIATE, EXCLUSIVE};
    const std::string transaction_mode(const TransactionMode mode);

}

#endif /* defines_hpp */
