//
//  ALDBTypeDefines.h
//  alloy
//
//  Created by Alex Lee on 03/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#ifndef ALDBTypeDefines_h
#define ALDBTypeDefines_h

#include "defines.hpp"
#include "order_clause.hpp"
#include "column_index.hpp"
#include "column_def.hpp"

typedef NS_ENUM(NSInteger, ALDBTransactionMode) {
    ALDBTransactionModeDefered      = (int8_t)aldb::TransactionMode::DEFERED,
    ALDBTransactionModeImmediate    = (int8_t)aldb::TransactionMode::IMMEDIATE,
    ALDBTransactionModeExclusive    = (int8_t)aldb::TransactionMode::EXCLUSIVE,
};

typedef NS_ENUM(NSInteger, ALDBColumnType) {
    ALDBColumnTypeNull      = (int8_t)aldb::ColumnType::NULL_T,
    ALDBColumnTypeInt       = (int8_t)aldb::ColumnType::INT32_T,
    ALDBColumnTypeLong      = (int8_t)aldb::ColumnType::INT64_T,
    ALDBColumnTypeDouble    = (int8_t)aldb::ColumnType::DOUBLE_T,
    ALDBColumnTypeText      = (int8_t)aldb::ColumnType::TEXT_T,
    ALDBColumnTypeBlob      = (int8_t)aldb::ColumnType::BLOB_T
};

typedef NS_ENUM(NSInteger, ALDBOrder) {
    ALDBOrderDefault = (int8_t)aldb::OrderBy::DEFAULT,
    ALDBOrderASC     = (int8_t)aldb::OrderBy::ASC,
    ALDBOrderDESC    = (int8_t)aldb::OrderBy::DESC
};

typedef NS_ENUM(NSInteger, ALDBConflictPolicy) {
    ALDBConflictPolicyDefault   = (int8_t)aldb::ConflictPolicy::DEFAULT,
    ALDBConflictPolicyReplace   = (int8_t)aldb::ConflictPolicy::REPLACE,
    ALDBConflictPolicyRollback  = (int8_t)aldb::ConflictPolicy::ROLLBACK,
    ALDBConflictPolicyAbort     = (int8_t)aldb::ConflictPolicy::ABORT,
    ALDBConflictPolicyFail      = (int8_t)aldb::ConflictPolicy::FAIL,
    ALDBConflictPolicyIgnore    = (int8_t)aldb::ConflictPolicy::IGNORE
};

typedef aldb::OrderClause ALDBOrderBy;
typedef aldb::IndexColumn ALDBIndex;
typedef aldb::ColumnDef   ALDBColumnDef;
typedef aldb::Column      ALDBColumn;

class ALDBExpr;
typedef ALDBExpr ALDBCondition;

#endif /* ALDBTypeDefines_h */
