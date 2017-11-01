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

#include "handle.hpp"
#include "in_case_lock_guard.hpp"
#include "transaction.hpp"
#include "sql_transaction.hpp"

namespace aldb {

Transaction::Transaction(const RecyclableHandle &handle)
    : CoreBase(CoreType::TRANSACTION), _handle(handle), /*_mutex(new std::mutex),*/ _inTransaction(false) {
    auto_commit = true;
}

const std::string &Transaction::get_path() const {
    return _handle->get_path();
}

RecyclableStatement Transaction::prepare(const std::string &sql, ErrorPtr &error) {
    std::lock_guard<std::mutex> lockGuard(_mutex);
    return CoreBase::prepare(_handle, sql, error);
}

bool Transaction::exec(const std::string &sql, ErrorPtr &error) {
    std::lock_guard<std::mutex> lockGuard(_mutex);
    return CoreBase::exec(_handle, sql, error);
}

bool Transaction::exec(const std::string &sql, const std::list<const SQLValue> &args, ErrorPtr &error) {
    std::lock_guard<std::mutex> lockGuard(_mutex);
    return CoreBase::exec(_handle, sql, args, error);
}

bool Transaction::exec(const SQLStatement &stmt, ErrorPtr &error) {
    return exec(stmt.sql(), stmt.values(), error);
}

bool Transaction::begin_transaction(const aldb::TransactionMode mode, ErrorPtr &error) {
    std::lock_guard<std::mutex> lockGuard(_mutex);
    if (CoreBase::exec(_handle, SQLTransaction().begin(mode), error)) {
        _inTransaction = true;
        return true;
    }
    return false;
}

bool Transaction::commit(ErrorPtr &error) {
    std::lock_guard<std::mutex> lockGuard(_mutex);
    bool result = CoreBase::exec(_handle, SQLTransaction().commit(), error);
    if (result) {
        _inTransaction = false;
    }
    return result;
}

bool Transaction::rollback(ErrorPtr &error) {
    std::lock_guard<std::mutex> lockGuard(_mutex);
    bool result    = CoreBase::exec(_handle, SQLTransaction().rollback(), error);
    _inTransaction = false;
    return result;
}

bool Transaction::exec_transaction(TransactionBlock transaction, TransactionEventBlock event_handle, ErrorPtr &error) {
    if (!transaction) {
        return true;
    }
    
    std::lock_guard<std::mutex> lockGuard(_mutex);
    if (_inTransaction) {
        bool rollback = false;
        transaction(rollback);
        return !rollback;
    }
    return CoreBase::exec_transaction(transaction, event_handle, error);
}

int Transaction::getChanges() {
    std::lock_guard<std::mutex> lockGuard(_mutex);
    return _handle->get_changes();
}

Transaction::~Transaction() {
    if (_inTransaction) {
        ErrorPtr error;
        if (auto_commit) {
            commit(error);
        } else {
            rollback(error);
        }
    }
}

}  // namespace aldb
