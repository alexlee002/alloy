
//
//  database.hpp
//  alloy
//
//  Created by Alex Lee on 25/07/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#ifndef database_hpp
#define database_hpp

#include <stdio.h>
#include <string>
#include <functional>
#include "concurrent_list.hpp"
#include "core_base.hpp"
#include "thread_local.hpp"

namespace aldb {

class Transaction;
class RecyclableHandle;
class Database : public CoreBase {
  public:
    Database() = delete;
    Database(const std::string &path, const Configs &default_configs, const DatabaseOpenCallback &on_opened);
    
    const std::string &get_path() const override;
    
    bool is_opened() const;
    void close(std::function<void(void)> on_closed);
    
    void set_config(const std::string &name, const Config &config, Configs::Order order);
    void set_config(const std::string &name, const Config &config);

    RecyclableStatement prepare(const std::string &sql) override;
    bool exec(const std::string &sql) override;
    bool exec(const std::string &sql, const std::list<const SQLValue> &args) override;
    
    bool exec_transaction(TransactionBlock transaction, TransactionEventBlock event_handle) override;

    bool begin_transaction(const aldb::TransactionMode mode) override;
    bool commit() override;
    bool rollback() override;

    std::shared_ptr<Transaction> getTransaction();

  protected:
    RecyclableHandle pop_handle();
    
    RecyclableHandlePool _pool;
    static ThreadLocal<std::unordered_map<std::string, RecyclableHandle>> _s_threadedHandle;
};
}

#endif /* database_hpp */
