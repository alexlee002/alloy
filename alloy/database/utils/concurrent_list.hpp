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

#ifndef concurrent_list_hpp
#define concurrent_list_hpp

#include <stdio.h>
#include <list>
#include <dispatch/dispatch.h>
//#include "gcd_lock_guard.hpp"
#include "spin.hpp"

// from WCDB, @link:https://github.com/Tencent/wcdb
namespace aldb {

template <typename T>
class ConcurrentList {
  public:
    using ElementType = std::shared_ptr<T>;

    ConcurrentList(size_t capacityCap) : _capacityCap(capacityCap) { /*_dsem = dispatch_semaphore_create(1);*/ }

    virtual ~ConcurrentList() { /*dispatch_release(_dsem);*/ }

    size_t capacity() const {
        SpinLockGuard<Spin> lockGuard(_spin);
        return _capacityCap;
    }

    bool push_back(const ElementType &value) {
        SpinLockGuard<Spin> lockGuard(_spin);
        if (_list.size() < _capacityCap) {
            _list.push_back(value);
            return true;
        }
        return false;
    }

    bool push_front(const ElementType &value) {
        SpinLockGuard<Spin> lockGuard(_spin);
        if (_list.size() < _capacityCap) {
            _list.push_front(value);
            return true;
        }
        return false;
    }

    ElementType pop_back() {
        SpinLockGuard<Spin> lockGuard(_spin);
        if (_list.empty()) {
            return nullptr;
        }
        ElementType value = _list.back();
        _list.pop_back();
        return value;
    }

    ElementType pop_front() {
        SpinLockGuard<Spin> lockGuard(_spin);
        if (_list.empty()) {
            return nullptr;
        }
        ElementType value = _list.front();
        _list.pop_front();
        return value;
    }

    bool is_empty() const {
        SpinLockGuard<Spin> lockGuard(_spin);
        return _list.empty();
    }

    size_t size() const {
        SpinLockGuard<Spin> lockGuard(_spin);
        return _list.size();
    }

    size_t clear() {
        SpinLockGuard<Spin> lockGuard(_spin);
        size_t size = _list.size();
        _list.clear();
        return size;
    }

  protected:
    std::list<ElementType> _list;
    size_t _capacityCap;
//    dispatch_semaphore_t _dsem;
    mutable Spin _spin;
};
}

#endif /* concurrent_list_hpp */
