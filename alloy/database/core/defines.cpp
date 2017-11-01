//
//  defines.cpp
//  alloy
//
//  Created by Alex Lee on 14/07/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#include "defines.hpp"
#include <iterator>
#include "utils.hpp"

namespace aldb {
    
const std::string SqliteErrorDomain = "Sqlite";
const std::string ALDBErrorDomain = "ALDB";
const std::string BinaryCollate = "BINARY";

const std::string column_type_name(const ColumnType type) {
    switch (type) {
        case ColumnType::NULL_T:
            return "NULL";

        case ColumnType::INT32_T://fall
        case ColumnType::INT64_T:
            return "INTEGER";

        case ColumnType::DOUBLE_T:
            return "REAL";
        case ColumnType::TEXT_T:
            return "TEXT";
        case ColumnType::BLOB_T:
            return "BLOB";

        default:
            return "BLOB";
    }
}
    
//@link: http://www.sqlite.org/datatype3.html
ColumnType column_type_for_name(const std::string &name) {
    std::string upper_name = aldb::str_to_upper(name);

    if (upper_name == "BOOLEAN" /* aldb implementation*/ ||
        upper_name == "TINYINT"  ||
        upper_name == "SMALLINT" ||
        upper_name == "INT2"     ||
        upper_name == "INT8") {
        return ColumnType::INT32_T;
    }
    if (upper_name == "INT"       ||
        upper_name == "INTEGER"   ||
        upper_name == "MEDIUMINT" ||
        upper_name == "BIGINT"    ||
        upper_name == "UNSIGNED BIG INT") {
        return ColumnType::INT64_T;
    }
    if (upper_name.find("TEXT") != std::string::npos ||
        upper_name.find("CHAR") != std::string::npos ||
        upper_name.find("CLOB") != std::string::npos) {
        return ColumnType::TEXT_T;
    }
    if (upper_name == "" || upper_name.find("BLOB") != std::string::npos) {
        return ColumnType::BLOB_T;
    }
    if (upper_name.find("REAL") != std::string::npos ||
        upper_name.find("FLOA") != std::string::npos ||
        upper_name.find("DOUB") != std::string::npos ||
        upper_name.find("DATE") != std::string::npos /* aldb implementation*/ ||
        upper_name == "NUMERIC" /* aldb implementation*/ ||
        upper_name.find("DECIMAL") != std::string::npos /* aldb implementation*/) {
        return ColumnType::DOUBLE_T;
    }
    
    return ColumnType::BLOB_T;
}

const std::string literal_default_time_value(DefaultTimeValue value) {
    switch (value) {
        case DefaultTimeValue::CURRENT_DATE:
            return "CURRENT_DATE";
        case DefaultTimeValue::CURRENT_TIME:
            return "CURRENT_TIME";
        case DefaultTimeValue::CURRENT_TIMESTAMP:
            return "CURRENT_TIMESTAMP";
        default:
            return "";
    }
}

DefaultTimeValue default_time_value_from_string(const std::string &str) {
    std::string upper_str = str_to_upper(str);
    if (upper_str == "CURRENT_DATE") {
        return DefaultTimeValue::CURRENT_DATE;
    } else if (upper_str == "CURRENT_TIME") {
        return DefaultTimeValue::CURRENT_TIME;
    } else if (upper_str == "CURRENT_TIMESTAMP") {
        return DefaultTimeValue::CURRENT_TIMESTAMP;
    } else {
        return DefaultTimeValue::NOT_SET;
    }
}

const std::string order_term(const OrderBy order) {
    switch (order) {
        case OrderBy::DEFAULT:
            return "";
        case OrderBy::DESC:
            return "DESC";
        case OrderBy::ASC:
            return "ASC";
        default:
            return "";
    }
}

const std::string conflict_term(const ConflictPolicy policy) {
    switch (policy) {
        case ConflictPolicy::REPLACE:
            return "REPLACE";
        case ConflictPolicy::ROLLBACK:
            return "ROLLBACK";
        case ConflictPolicy::ABORT:
            return "ABORT";
        case ConflictPolicy::FAIL:
            return "FAIL";
        case ConflictPolicy::IGNORE:
            return "IGNORE";
        default:
            return "";
    }
}

const std::string transaction_mode(const TransactionMode mode) {
    switch (mode) {
        case TransactionMode::DEFERED:
            return "DEFERED";
        case TransactionMode::IMMEDIATE:
            return "IMMEDIATE";
        case TransactionMode::EXCLUSIVE:
            return "EXCLUSIVE";
        default:
            return "";
    }
}

}
