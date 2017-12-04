//
//  handle.hpp
//  alloy
//
//  Created by Alex Lee on 22/07/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//
//  Fork from WCDB, github: https://github.com/tencent/wcdb
//

#ifndef handle_hpp
#define handle_hpp

#include <stdio.h>
#include <string>
#include <list>
#include <unordered_map>
#include <mutex>
#include "recyclable.hpp"
#include "catchable.hpp"

namespace aldb {

class SQLValue;
class StatementHandle;
class Configs;
class Error;

class Handle : public Catchable {
  public:
    Handle(const std::string &path);
    virtual ~Handle();

    void cache_statement_for_sql(const std::string &sql);

    bool open();
    void close();

    std::shared_ptr<StatementHandle> prepare(const std::string &sql);
    bool exec(const std::string &sql);
    bool exec(const std::string &sql, const std::list<const aldb::SQLValue> &args);

    int64_t last_inserted_rowid();

    const std::string &get_path() const;
    
    int get_changes() const;
  
    uint64_t busy_time;
    __uint64_t threadid;
    
    
#pragma mark - sqlite functions
    void register_wal_commited_hook(int (*hook)(aldb::Handle *, sqlite3 *, const char *, int /*pages*/),
                                    void *info);

    void register_custom_sql_function(const std::string &name, int argc, void (*func)(void *, int, void **));

    void register_sqlite_busy_handler(int (*busy_handler)(void *, int));
    
//    void register_custom_collation(const std::string &name, int(*func)(void*,int,const void*,int,const void*));


  protected:
    Handle(const Handle &) = delete;
    Handle &operator=(const Handle &) = delete;
    
    const std::string _path;
    void *_handle;
    bool _cache_stmt;
    std::unordered_map<std::string, std::shared_ptr<StatementHandle>> _stmt_caches;
};
}

#endif /* handle_hpp */