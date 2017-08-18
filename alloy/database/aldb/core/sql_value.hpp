//
//  sql_expr_value.hpp
//  patchwork
//
//  Created by Alex Lee on 13/07/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#ifndef sql_value_hpp
#define sql_value_hpp

#include <stdio.h>
#include "defines.hpp"
#include "utils.hpp"

namespace aldb {

struct SQLValue {
    aldb::ColumnType val_type;
    size_t val_size; // only available for BLOB type
    union {
        int32_t     i32_val;
        int64_t     i64_val;
        double      d_val;
        std::string s_val;
    };
    
    SQLValue() : val_type(aldb::ColumnType::NULL_T) {}
    SQLValue(bool val)            : val_type(aldb::ColumnType::INT32_T), val_size(0), i32_val(val ? 1 : 0){}
    SQLValue(const int32_t i)     : val_type(aldb::ColumnType::INT32_T), val_size(0), i32_val(i)  {}
    SQLValue(const int64_t l)     : val_type(aldb::ColumnType::INT64_T), val_size(0), i64_val(l)  {}
    SQLValue(const double d)      : val_type(aldb::ColumnType::DOUBLE_T),val_size(0), d_val(d)    {}
    SQLValue(const std::string &s): val_type(aldb::ColumnType::TEXT_T),  val_size(0), s_val(s)    {}
    SQLValue(const std::nullptr_t): val_type(aldb::ColumnType::NULL_T),  val_size(0)            {}
    
    SQLValue(const char *c) {
        if (c) {
            val_type = aldb::ColumnType::TEXT_T, ::new (&s_val) std::string(c);
        } else {
            val_type = aldb::ColumnType::NULL_T;
        }
        val_size = 0;
    }
    
    SQLValue(const void *b, size_t size) {
        if (b) {
            val_type = aldb::ColumnType::BLOB_T, ::new (&s_val) std::string((const char *)b, size);
        } else {
            val_type = aldb::ColumnType::NULL_T;
        }
        val_size = size;
    }
    
    SQLValue(SQLValue const &o): val_type(o.val_type) {
        switch (o.val_type) {
            case aldb::ColumnType::INT32_T:
                i32_val = o.i32_val;
                break;
            case aldb::ColumnType::INT64_T:
                i64_val = o.i64_val;
                break;
            case aldb::ColumnType::DOUBLE_T:
                d_val = o.d_val;
                break;
                
            case aldb::ColumnType::TEXT_T: //fall
            case aldb::ColumnType::BLOB_T:
                ::new (&s_val) auto(o.s_val);
                break;
            default:
                break;
        }
        val_size = o.val_size;
    }
    
    ~SQLValue() {
        if (val_type == aldb::ColumnType::TEXT_T || val_type == aldb::ColumnType::BLOB_T) {
            using s_type = std::string;
            s_val.~s_type();
        }
    }
    
    bool operator==(const SQLValue &o) const {
        if (val_type != o.val_type) { return false; }
        switch(val_type) {
            case aldb::ColumnType::INT32_T:
                return i32_val == o.i32_val;
            case aldb::ColumnType::INT64_T:
                return i64_val == o.i64_val;
            case aldb::ColumnType::DOUBLE_T:
                return d_val == o.d_val;
                
            case aldb::ColumnType::TEXT_T: //fall
            case aldb::ColumnType::BLOB_T:
                return s_val == o.s_val;
            default:
                return false;
        }
    }
    
    SQLValue operator=(const SQLValue &o) {
        val_type = o.val_type;
        switch (o.val_type) {
            case aldb::ColumnType::INT32_T:
                i32_val = o.i32_val;
                break;
            case aldb::ColumnType::INT64_T:
                i64_val = o.i64_val;
                break;
            case aldb::ColumnType::DOUBLE_T:
                d_val = o.d_val;
                break;
                
            case aldb::ColumnType::TEXT_T: //fall
            case aldb::ColumnType::BLOB_T:
                ::new (&s_val) auto(o.s_val);
                break;
            default:
                break;
        }
        val_size = o.val_size;
        
        return *this;
    }
    
    operator std::string() const {
        switch (val_type) {
            case aldb::ColumnType::INT32_T:
                return std::to_string(i32_val);
            case aldb::ColumnType::INT64_T:
                return std::to_string(i64_val);
            case aldb::ColumnType::DOUBLE_T:
                return std::to_string(d_val);
                
            case aldb::ColumnType::TEXT_T:
                return aldb::literal_value(s_val);
            case aldb::ColumnType::BLOB_T:
                return aldb::literal_value(s_val, true);
            default:
                return "";
        }
    }
};
    
} // end of namespace aldb

#endif /* sql_value_hpp */
