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
#include <unordered_map>

namespace aldb {

class Handle;
typedef std::function<bool(std::shared_ptr<Handle> &)> DBInitializer;

class HandlePool;
typedef Recyclable<std::shared_ptr<HandlePool>> RecyclableHandlePool;

class Error;
class HandlePool : public Catchable {
  public:
    static RecyclableHandlePool get_pool(const std::string &path,
                                         const Configs &default_configs,
                                         const DBInitializer &initializer);
    
    static RecyclableHandlePool get_pool(const std::string &path);
    
    static void purge_all_free_handles();

  protected:
    static std::unordered_map<std::string, std::pair<std::shared_ptr<HandlePool>, int>>
        _s_pools;  // path->{pool, reference}
    static std::mutex _s_mutex;

  public:
    //    std::atomic<Tag> tag;
    const std::string path;
    std::atomic<int> max_concurrency;
    
    RecyclableHandle flow_out(ErrorPtr &error);
    bool fill_one(ErrorPtr &error);

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
    HandlePool(const std::string &path, const Configs &configs, const DBInitializer &initializer);
    
    HandlePool(const HandlePool &) = delete;
    HandlePool &operator=(const HandlePool &) = delete;

    std::shared_ptr<HandleWrap> init_handle(ErrorPtr &error);
    std::shared_ptr<HandleWrap> generate_handle(ErrorPtr &error);

    bool apply_configs(std::shared_ptr<HandleWrap> &handle, ErrorPtr &error);
    void flow_back(const std::shared_ptr<HandleWrap> &handle);

    ConcurrentList<HandleWrap> _handles;
    std::atomic<int> _aliveHandleCount;
    const DBInitializer _initializer;
    std::atomic<bool> _db_inited;

    Configs _configs;
    RWLock _rwlock;
    std::mutex _db_init_mutex;

    static const int _s_hardware_concurrency;
};

}  // namespace aldb

#endif /* handle_pool_hpp */
