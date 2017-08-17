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

#include "handle_recyclable.hpp"

namespace aldb {

HandleWrap::HandleWrap(const std::shared_ptr<Handle> &handle, const Configs &configs)
    : handle(handle), configs(configs) {}

#pragma mark - RecyclableHandle
RecyclableHandle::RecyclableHandle(const std::shared_ptr<HandleWrap> &value,
                                   const Recyclable<std::shared_ptr<HandleWrap>>::OnRecycled &onRecycled)
    : _value(value), _recyclable(value, onRecycled) {}

RecyclableHandle::operator bool() const { return _value != nullptr; }

bool RecyclableHandle::operator!=(const std::nullptr_t &) const { return _value != nullptr; }

bool RecyclableHandle::operator==(const std::nullptr_t &) const { return _value == nullptr; }

RecyclableHandle &RecyclableHandle::operator=(const std::nullptr_t &) {
    _value      = nullptr;
    _recyclable = nullptr;
    return *this;
}

}  // namespace aldb
