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

namespace aldb {

Transaction::Transaction(const RecyclableHandle &handle)
    : CoreBase(CoreType::TRANSACTION), _handle(handle), /*_mutex(new std::mutex),*/ _inTransaction(false) {
    auto_commit = true;
}

const std::string &Transaction::get_path() const { return _handle->get_path(); }

RecyclableStatement Transaction::prepare(const std::string &sql) {
    std::lock_guard<std::mutex> lockGuard(_mutex);
    return CoreBase::prepare(_handle, sql);
}

bool Transaction::exec(const std::string &sql) {
    std::lock_guard<std::mutex> lockGuard(_mutex);
    return CoreBase::exec(_handle, sql);
}

bool Transaction::exec(const std::string &sql, const std::list<const SQLValue> &args) {
    std::lock_guard<std::mutex> lockGuard(_mutex);
    return CoreBase::exec(_handle, sql, args);
}

bool Transaction::begin_transaction(const aldb::TransactionMode mode) {
    std::lock_guard<std::mutex> lockGuard(_mutex);
    if (CoreBase::exec(_handle, "BEGIN " + transaction_mode(mode))) {
        _inTransaction = true;
        return true;
    }
    return false;
}

bool Transaction::commit() {
    std::lock_guard<std::mutex> lockGuard(_mutex);
    bool result = CoreBase::exec(_handle, "COMMIT");
    if (result) {
        _inTransaction = false;
    }
    return result;
}

bool Transaction::rollback() {
    std::lock_guard<std::mutex> lockGuard(_mutex);
    bool result    = CoreBase::exec(_handle, "ROLLBACK");
    _inTransaction = false;
    return result;
}

bool Transaction::exec_transaction(TransactionBlock transaction, TransactionEventBlock event_handle) {
    std::lock_guard<std::mutex> lockGuard(_mutex);
    if (_inTransaction) {
        return transaction();
    }
    return CoreBase::exec_transaction(transaction, event_handle);
}

int Transaction::getChanges() {
    std::lock_guard<std::mutex> lockGuard(_mutex);
    return _handle->get_changes();
}

Transaction::~Transaction() {
    if (_inTransaction) {
        if (auto_commit) {
            commit();
        } else {
            rollback();
        }
    }
}

}  // namespace aldb
