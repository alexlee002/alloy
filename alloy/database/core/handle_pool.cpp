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
#include "handle_pool.hpp"
#include "defines.hpp"
#include "macros.h"
#include "error.hpp"
#include <thread>
#include <unordered_map>

namespace aldb {

std::unordered_map<std::string, std::pair<std::shared_ptr<HandlePool>, int>> HandlePool::_s_pools;
std::mutex HandlePool::_s_mutex;
const int HandlePool::_s_hardware_concurrency = std::thread::hardware_concurrency();

RecyclableHandlePool HandlePool::get_pool(const std::string &path,
                                          const Configs &default_configs,
                                          const DBInitializer &initializer) {
    std::shared_ptr<HandlePool> pool = nullptr;
    std::lock_guard<std::mutex> lockGuard(_s_mutex);
    auto iter = _s_pools.find(path);
    if (iter == _s_pools.end()) {
        pool.reset(new HandlePool(path, default_configs, initializer));
        _s_pools.insert({path, {pool, 1}});
    } else {
        pool = iter->second.first;
        ++iter->second.second;
    }
    
    return RecyclableHandlePool(pool, [](std::shared_ptr<HandlePool> &pool) {
        std::lock_guard<std::mutex> lockGuard(_s_mutex);
        const auto &iter = _s_pools.find(pool->path);
        if (--iter->second.second == 0) {
            _s_pools.erase(iter);
        }
    });
}

RecyclableHandlePool HandlePool::get_pool(const std::string &path) {
    std::lock_guard<std::mutex> lockGuard(_s_mutex);
    auto iter = _s_pools.find(path);
    if (iter != _s_pools.end()) {
        ++iter->second.second;
        return RecyclableHandlePool(iter->second.first, [](std::shared_ptr<HandlePool> &pool) {
            std::lock_guard<std::mutex> lockGuard(_s_mutex);
            const auto &iter = _s_pools.find(pool->path);
            if (--iter->second.second == 0) {
                _s_pools.erase(iter);
            }
        });
    }

    return RecyclableHandlePool(nullptr, nullptr);
}

void HandlePool::purge_all_free_handles() {
    std::list<std::shared_ptr<HandlePool>> handlePools;
    {
        std::lock_guard<std::mutex> lockGuard(_s_mutex);
        for (const auto &iter : _s_pools) {
            handlePools.push_back(iter.second.first);
        }
    }
    for (const auto &handlePool : handlePools) {
        handlePool->purge_free_handles();
    }
}

HandlePool::HandlePool(const std::string &thePath, const Configs &configs, const DBInitializer &initializer)
    : aldb::Catchable()
    , path(thePath)
    , max_concurrency(64)
    , _handles(std::min(_s_hardware_concurrency, max_concurrency.load()))
    , _aliveHandleCount(0)
    , _initializer(initializer)
    , _db_inited(false)
    , _configs(configs) {}

void HandlePool::block() {
    _rwlock.lock_write();
}

void HandlePool::unblock() {
    _rwlock.unlock_write();
}

bool HandlePool::is_blocked() const {
    return _rwlock.writing();
}

void HandlePool::drain(HandlePool::OnDrained on_drained) {
    _rwlock.lock_write();
    int size = (int) _handles.clear();
    _aliveHandleCount -= size;
    if (on_drained) {
        on_drained();
    }
    _rwlock.unlock_write();
}

void HandlePool::purge_free_handles() {
    _rwlock.lock_read();
    int size = (int) _handles.clear();
    _aliveHandleCount -= size;
    _rwlock.unlock_read();
}

bool HandlePool::is_drained() const {
    return _aliveHandleCount == 0;
}

RecyclableHandle HandlePool::flow_out(ErrorPtr &error) {
    _rwlock.lock_read();
    std::shared_ptr<HandleWrap> handleWrap = _handles.pop_back();
    if (handleWrap == nullptr) {
        if (_aliveHandleCount < max_concurrency) {
            handleWrap = init_handle(error);
            if (handleWrap) {
                ++_aliveHandleCount;
            }
        } else {
            error = std::shared_ptr<Error>(new Error(aldb::ALDBErrorDomain,
                                                     (int) aldb::ErrorCode::DB_CONNS_EXCEED,
                                                     ("Database connections out of limit! Database: " + path).c_str()));
        }
    }
    if (handleWrap) {
        if (apply_configs(handleWrap, error)) {
            handleWrap->operator->()->threadid = __ALDB_CURRENT_THREAD_ID();
            return RecyclableHandle(handleWrap,
                                    [this](std::shared_ptr<HandleWrap> &handleWrap) { flow_back(handleWrap); });
        }
    }

    handleWrap = nullptr;
    _rwlock.unlock_read();
    return RecyclableHandle(nullptr, nullptr);
}

void HandlePool::flow_back(const std::shared_ptr<HandleWrap> &handleWrap) {
    if (handleWrap) {
        handleWrap->operator->()->threadid = 0;

        bool inserted = _handles.push_back(handleWrap);
        _rwlock.unlock_read();
        if (!inserted) {
            --_aliveHandleCount;
        }
    }
}

std::shared_ptr<HandleWrap> HandlePool::generate_handle(ErrorPtr &error) {
    std::shared_ptr<Handle> handle(new Handle(path));
    if (!handle->open()) {
        error = handle->get_error();
        return nullptr;
    }

    Configs defaultConfigs = _configs;  // cache config to avoid multi-thread assigning
    if (defaultConfigs.apply_configs(handle, error)) {
        return std::shared_ptr<HandleWrap>(new HandleWrap(handle, defaultConfigs));
    }
    return nullptr;
}

std::shared_ptr<HandleWrap> HandlePool::init_handle(ErrorPtr &error) {
    if (!_db_inited) {
        std::lock_guard<std::mutex> lock(_db_init_mutex);
        std::shared_ptr<HandleWrap> wrap = generate_handle(error);
        if (wrap) {
            if (!_db_inited) {
                if (_initializer) {
                    if (!_initializer(wrap->handle)) {
                        error = std::shared_ptr<Error>(new Error(aldb::ALDBErrorDomain,
                                                                 (int) aldb::ErrorCode::DB_INIT_ERROR,
                                                                 ("Can not initialize database: " + path).c_str()));
                        return nullptr;
                    }
                }
                _db_inited = true;
            }
        }
        return wrap;
    }
    return generate_handle(error);
}

bool HandlePool::fill_one(ErrorPtr &error) {
    _rwlock.lock_read();
    std::shared_ptr<HandleWrap> handleWrap = init_handle(error);
    bool result = false;
    if (handleWrap) {
        result = true;
        bool inserted = _handles.push_back(handleWrap);
        if (inserted) {
            ++_aliveHandleCount;
        }
    }
    _rwlock.unlock_read();
    return result;
}

bool HandlePool::apply_configs(std::shared_ptr<HandleWrap> &handleWrap, ErrorPtr &error) {
    Configs newConfigs = _configs;  // cache config to avoid multi-thread assigning
    if (newConfigs != handleWrap->configs) {
        if (!newConfigs.apply_configs(handleWrap->handle, error)) {
            return false;
        }
        handleWrap->configs = newConfigs;
    }
    return true;
}

void HandlePool::set_config(const std::string &name, const Config &config, Configs::Order order) {
    _configs.set_config(name, config, order);
}

void HandlePool::set_config(const std::string &name, const Config &config) {
    _configs.set_config(name, config);
}

}  // namespace aldb

