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

#ifndef handle_pool_hpp
#define handle_pool_hpp

#include "concurrent_list.hpp"
#include "config.hpp"
#include "handle_recyclable.hpp"
#include "recyclable.hpp"
#include "rwlock.hpp"
#include "catchable.hpp"
#include <unordered_map>

namespace aldb {

class Handle;
typedef std::function<bool(const RecyclableHandle &)> DatabaseOpenCallback;

class HandlePool;
typedef Recyclable<std::shared_ptr<HandlePool>> RecyclableHandlePool;

class Error;
class HandlePool : public Catchable {
  public:
    static RecyclableHandlePool get_pool(const std::string &path,
                                         const Configs &default_configs,
                                         const DatabaseOpenCallback &open_callback);
    static void purge_all_free_handles();

  protected:
    static std::unordered_map<std::string, std::pair<std::shared_ptr<HandlePool>, int>>
        _s_pools;  // path->{pool, reference}
    static std::mutex _s_mutex;

  public:
    //    std::atomic<Tag> tag;
    const std::string path;
    std::atomic<int> maxConcurrency;

    RecyclableHandle flow_out();
    bool fill_one();

    typedef std::function<void(void)> OnDrained;
    void drain(HandlePool::OnDrained on_drained);
    bool is_drained() const;
    
    void block();
    void unblock();
    bool is_blocked() const;

    void purge_free_handles();

    void set_config(const std::string &name, const Config &config, Configs::Order order);
    void set_config(const std::string &name, const Config &config);

  protected:
    HandlePool(const std::string &path, const Configs &configs, const DatabaseOpenCallback &open_callback);
    
    HandlePool(const HandlePool &) = delete;
    HandlePool &operator=(const HandlePool &) = delete;

    std::shared_ptr<HandleWrap> init_handle();

    bool apply_configs(std::shared_ptr<HandleWrap> &handleWrap);
    void flow_back(const std::shared_ptr<HandleWrap> &handleWrap);

    ConcurrentList<HandleWrap> _handles;
    std::atomic<int> _aliveHandleCount;
    const DatabaseOpenCallback _open_callback;
    std::atomic<bool> _opened;

    Configs _configs;
    RWLock _rwlock;
    std::mutex _mutex;

    static const int _s_hardwareConcurrency;
};

}  // namespace aldb

#endif /* handle_pool_hpp */
