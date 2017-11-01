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

#include "statement_recyclable.hpp"

namespace aldb {

RecyclableStatement::RecyclableStatement(const RecyclableHandle &handle,
                                         const std::shared_ptr<StatementHandle> &statementHandle)
        : _handle(handle), _statementHandle(statementHandle) {
}

RecyclableStatement::RecyclableStatement() : _statementHandle(nullptr), _handle({nullptr, nullptr}) {
}

RecyclableStatement::operator bool() const {
    return _statementHandle != nullptr;
}

bool RecyclableStatement::operator!=(const std::nullptr_t &) const {
    return _statementHandle != nullptr;
}

bool RecyclableStatement::operator==(const std::nullptr_t &) const {
    return _statementHandle == nullptr;
}

RecyclableStatement &RecyclableStatement::operator=(const std::nullptr_t &) {
    _statementHandle = nullptr;
    _handle          = nullptr;
    return *this;
}

}  // namespace aldb
