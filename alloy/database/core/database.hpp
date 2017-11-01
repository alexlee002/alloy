
//
//  database.hpp
//  alloy
//
//  Created by Alex Lee on 25/07/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//
//  Fork from WCDB, github: https://github.com/tencent/wcdb
//

#ifndef database_hpp
#define database_hpp

#include <stdio.h>
#include <string>
#include <unordered_set>
#include <functional>
#include "concurrent_list.hpp"
#include "core_base.hpp"
#include "thread_local.hpp"
#include "sql_statement.hpp"

namespace aldb {

class Transaction;
class RecyclableHandle;
class Database : public CoreBase {
  public:
    
    Database() = delete;
    Database(const std::string &path, const Configs &default_configs, const DBInitializer &initializer);
    Database(const std::string &path);

    const std::string &get_path() const override;
    void set_max_concurrency(int size);

    void cache_statement_for_sql(const std::string &sql);
    
    bool is_valid() const;
    bool is_opened() const;
    void close(std::function<void(void)> on_closed);
    
    enum class ConfigOrder : Configs::Order {
        BUSY_HANDLER = 0,
        TRACE,
        CIPHER,
        BASE_CONFIG,
        LOCKING_MODE,
        SYNCHRONOUS,
        JOURNAL_MODE,
        CHECKPOINT,
        TOKENIZE,
        CACHESIZE,
        PAGESIZE,
    };
    
    void set_config(const std::string &name, const Config &config, Configs::Order order);
    void set_config(const std::string &name, const Config &config);

    RecyclableStatement prepare(const std::string &sql, ErrorPtr &error) override;
    bool exec(const std::string &sql, ErrorPtr &error) override;
    bool exec(const std::string &sql, const std::list<const SQLValue> &args, ErrorPtr &error) override;
    bool exec(const SQLStatement &sql, ErrorPtr &error) override;
    
    bool exec_transaction(TransactionBlock transaction, TransactionEventBlock event_handle, ErrorPtr &error) override;

    bool begin_transaction(const aldb::TransactionMode mode, ErrorPtr &error) override;
    bool commit(ErrorPtr &error) override;
    bool rollback(ErrorPtr &error) override;

    std::shared_ptr<Transaction> getTransaction(ErrorPtr &error);

  protected:
    RecyclableHandle pop_handle(ErrorPtr &error);
    
    RecyclableHandlePool _pool;
    
    static std::unordered_map<std::string/* path */, std::unordered_set<std::string>/* sqls */> _s_cached_sqls;
    static ThreadLocal<std::unordered_map<std::string/* path */, RecyclableHandle>> _s_threadedHandle;    
};
}

#endif /* database_hpp */
