/*
 * Tencent is pleased to support the open source community by making
 * WCDB available.
 *
 * Copyright (C) 2017 THL A29 Limited, a Tencent company.
 * All rights reserved.
 *
 * Licensed under the BSD 3-Clause License (the "License"); you may not use
 * this file except in compliance with the License. You may obtain a copy of
 * the License at
 *
 *       https://opensource.org/licenses/BSD-3-Clause
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "core_base.hpp"
#include "statement_handle.hpp"
#include "sql_value.hpp"

namespace aldb {

CoreBase::CoreBase(/*const RecyclableHandlePool &pool, */CoreType type)
    :aldb::Catchable()
    , _type(type)/*, _pool(pool)*/ {}

//const std::string &CoreBase::get_path() const { return _pool->path; }

CoreType CoreBase::get_type() const { return _type; }

RecyclableStatement CoreBase::prepare(const RecyclableHandle &handle, const std::string &sql) {
    std::shared_ptr<StatementHandle> statementHandle = nullptr;

    if (handle) {
        statementHandle = handle->prepare(sql);
        Catchable::raise_error(handle->get_error());
    }
    return RecyclableStatement(handle, statementHandle);
}

bool CoreBase::exec(const RecyclableHandle &handle, const std::string &sql) {
    bool result = false;
    if (handle) {
        result = handle->exec(sql);
        Catchable::raise_error(handle->get_error());
    }
    return result;
}

bool CoreBase::exec(const RecyclableHandle &handle, const std::string &sql, const std::list<const SQLValue> &args) {
    bool result = false;
    if (handle) {
        result = handle->exec(sql, args);
        Catchable::raise_error(handle->get_error());
    }
    return result;
}

bool CoreBase::exec_transaction(TransactionBlock transaction, TransactionEventBlock event_handle) {
    #define TRANSATION_EVENT(eventType)        \
        if (event_handle) {                    \
            event_handle(eventType);           \
        }
    
    if (!transaction) {
        return true;
    }
    
    if (!begin_transaction(aldb::TransactionMode::IMMEDIATE)) {
        TRANSATION_EVENT(TransactionEvent::BEGIN_FAILED);
        return false;
    }
    
    bool need_rollback = false;
    transaction(need_rollback);
    if (!need_rollback) {
        //User discards error
        if (commit()) {
            return true;
        }
        TRANSATION_EVENT(TransactionEvent::COMMIT_FAILED);
    }
    TRANSATION_EVENT(TransactionEvent::ROLLBACK);

    if (!rollback()) {
        TRANSATION_EVENT(TransactionEvent::ROLLBACK_FAILED);
    }
    return false;
}


}  // namespace aldb
