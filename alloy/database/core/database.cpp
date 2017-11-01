//
//  database.cpp
//  alloy
//
//  Created by Alex Lee on 25/07/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#include "database.hpp"
#include "statement_handle.hpp"
#include "sql_value.hpp"
#include "transaction.hpp"
#include "sql_transaction.hpp"

namespace aldb {

ThreadLocal<std::unordered_map<std::string, RecyclableHandle>> Database::_s_threadedHandle;
std::unordered_map<std::string /* path */, std::unordered_set<std::string> /* sqls */> Database::_s_cached_sqls;

Database::Database(const std::string &path, const Configs &default_configs, const DBInitializer &initializer)
    : aldb::CoreBase(CoreType::DATABASE), _pool(HandlePool::get_pool(path, default_configs, initializer)){};

Database::Database(const std::string &path) : aldb::CoreBase(CoreType::DATABASE), _pool(HandlePool::get_pool(path)) {
}

const std::string &Database::get_path() const {
    if (_pool == nullptr) {
        static std::string sDummyPath = "";
        return sDummyPath;
    }
    return _pool->path;
}

void Database::set_max_concurrency(int size) {
    if (_pool != nullptr) {
        _pool->max_concurrency = size;
    }
}

void Database::cache_statement_for_sql(const std::string &sql) {
    auto it = _s_cached_sqls.find(get_path());
    std::unordered_set<std::string> sqls;
    if (it != _s_cached_sqls.end()) {
        sqls = it->second;
    }
    if (sqls.find(sql) != sqls.end()) {  // already exists
        return;
    }

    sqls.insert(sql);
    _s_cached_sqls.insert({get_path(), sqls});

    set_config("aldb-enable-cache-statement", [sqls](std::shared_ptr<Handle> &handle, ErrorPtr &error) -> bool {
        for (auto sql : sqls) {
            handle->cache_statement_for_sql(sql);
        }
        return true;
    });
}

bool Database::is_opened() const {
    return _pool != nullptr && !_pool->is_drained();
}

void Database::close(std::function<void(void)> on_closed) {
    if (_pool != nullptr) {
        _pool->drain(on_closed);
    }
}

void Database::set_config(const std::string &name, const Config &config, Configs::Order order) {
    if (_pool != nullptr) {
        _pool->set_config(name, config, order);
    }
}

void Database::set_config(const std::string &name, const Config &config) {
    if (_pool != nullptr) {
        _pool->set_config(name, config);
    }
}

RecyclableStatement Database::prepare(const std::string &sql, ErrorPtr &error) {
    RecyclableHandle handle = pop_handle(error);
    return CoreBase::prepare(handle, sql, error);
}

bool Database::exec(const SQLStatement &stmt, ErrorPtr &error) {
    return CoreBase::exec(pop_handle(error), stmt.sql(), stmt.values(), error);
}

bool Database::exec(const std::string &sql, ErrorPtr &error) {
    return CoreBase::exec(pop_handle(error), sql, error);
}

bool Database::exec(const std::string &sql, const std::list<const SQLValue> &args, ErrorPtr &error) {
    return CoreBase::exec(pop_handle(error), sql, args, error);
}

bool Database::exec_transaction(TransactionBlock transaction, TransactionEventBlock event_handle, ErrorPtr &error) {
    if (!transaction) {
        return true;
    }

    std::unordered_map<std::string, RecyclableHandle> *threadedHandle = _s_threadedHandle.get();
    if (threadedHandle->find(get_path()) != threadedHandle->end()) {
        bool rollback = false;
        transaction(rollback);
        return !rollback;
    }
    return CoreBase::exec_transaction(transaction, event_handle, error);
}

bool Database::begin_transaction(const aldb::TransactionMode mode, ErrorPtr &error) {
    RecyclableHandle handle = pop_handle(error);
    if (handle != nullptr && CoreBase::exec(handle, SQLTransaction().begin(mode), error)) {
        std::unordered_map<std::string, RecyclableHandle> *threadedHandle = _s_threadedHandle.get();
        threadedHandle->insert({get_path(), handle});
        return true;
    }
    return false;
}

bool Database::commit(ErrorPtr &error) {
    RecyclableHandle handle = pop_handle(error);
    if (handle != nullptr && CoreBase::exec(handle, SQLTransaction().commit(), error)) {
        std::unordered_map<std::string, RecyclableHandle> *threadedHandle = _s_threadedHandle.get();
        threadedHandle->erase(get_path());
        return true;
    }
    return false;
}

bool Database::rollback(ErrorPtr &error) {
    RecyclableHandle handle = pop_handle(error);
    bool result             = false;
    if (handle != nullptr) {
        result = CoreBase::exec(handle, SQLTransaction().rollback(), error);
        std::unordered_map<std::string, RecyclableHandle> *threadedHandle = _s_threadedHandle.get();
        threadedHandle->erase(get_path());
    }
    return result;
}

std::shared_ptr<Transaction> Database::getTransaction(ErrorPtr &error) {
    if (_pool != nullptr) {
        RecyclableHandle handle = _pool->flow_out(error);  // get a new handle for transaction
        if (handle != nullptr) {
            return std::shared_ptr<Transaction>(new Transaction(handle));
        }
    }
    return nullptr;
}

RecyclableHandle Database::pop_handle(ErrorPtr &error) {
    std::unordered_map<std::string, RecyclableHandle> *threadedHandle = _s_threadedHandle.get();
    const auto &iter = threadedHandle->find(get_path());
    if (iter == threadedHandle->end()) {
        return _pool != nullptr ?  _pool->flow_out(error) : RecyclableHandle(nullptr, nullptr);
    }
    return iter->second;
}
}
