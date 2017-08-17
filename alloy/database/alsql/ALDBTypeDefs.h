//
//  ALDBTypeDefs.h
//  alloy
//
//  Created by Alex Lee on 28/07/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#ifndef ALDBTypeDefs_h
#define ALDBTypeDefs_h

#include "defines.hpp"
#include "core_base.hpp"

typedef NS_ENUM(NSInteger, ALDBTransactionMode) {
    ALDBTransactionModeDefered      = (int8_t)aldb::TransactionMode::DEFERED,
    ALDBTransactionModeImmediate    = (int8_t)aldb::TransactionMode::IMMEDIATE,
    ALDBTransactionModeExclusive    = (int8_t)aldb::TransactionMode::EXCLUSIVE,
};

typedef NS_ENUM(NSInteger, ALDBTransactionEvent) {
    ALDBTransactionEventBeginFailed     = (int8_t)aldb::CoreBase::TransactionEvent::BEGIN_FAILED,
    ALDBTransactionEventCommitFailed    = (int8_t)aldb::CoreBase::TransactionEvent::COMMIT_FAILED,
    ALDBTransactionEventRollback        = (int8_t)aldb::CoreBase::TransactionEvent::ROLLBACK,
    ALDBTransactionEventRollbackFailed  = (int8_t)aldb::CoreBase::TransactionEvent::ROLLBACK_FAILED,
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

typedef NS_ENUM(NSInteger, ALDBDefaultTime) {
    ALDBDefaultTimeCurrentTime      /*= (int8_t)aldb::ColumnDefine::DefaultTime::CURRENT_TIME*/,
    ALDBDefaultTimeCurrentDate      /*= (int8_t)aldb::ColumnDefine::DefaultTime::CURRENT_DATE*/,
    ALDBDefaultTimeCurrentDateTime  /*= (int8_t)aldb::ColumnDefine::DefaultTime::CURRENT_DATE_TIME*/
};

class ALSQLClause;
typedef ALSQLClause ALDBCondition;

typedef int16_t ALDBOptrPrecedence; // sql operator precedence

#endif /* ALDBTypeDefs_h */
