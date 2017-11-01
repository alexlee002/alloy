//
//  statement_handle.hpp
//  alloy
//
//  Created by Alex Lee on 23/07/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//
//  Fork from WCDB, github: https://github.com/tencent/wcdb
//

#ifndef statement_handle_hpp
#define statement_handle_hpp

#include <stdio.h>
#include <string>
#include <unordered_map>
#include "catchable.hpp"
#include "defines.hpp"

namespace aldb {
class SQLValue;
class Handle;
class Error;

class StatementHandle : public Catchable {
  public:
    virtual ~StatementHandle();
    void finalize();

    bool next_row();
    bool exec();

    bool reset_bindings();
    bool bind_value(const SQLValue &value, const int index);

    const int32_t get_int32_value(int index) const;
    const int64_t get_int64_value(int index) const;
    const double get_double_value(int index) const;
    const char *get_text_value(int index) const;
    const void *get_blob_value(int index, size_t &size) const;

    int64_t last_insert_rowid() const;
    int changes() const;
    
    int column_count() const;
    const char *column_name(int idx) const;
    int column_index(const char *name);
    ColumnType column_type(int idx) const;
    const char *sql() const;
    const char *expanded_sql() const;

    __uint64_t threadid;

  protected:
    StatementHandle(const Handle &handle, void *stmt);
    const StatementHandle &operator=(const StatementHandle &other) = delete;
    StatementHandle(const StatementHandle &other)                  = delete;
    
    int step();

    const Handle &_hadler;
    void *_stmt;

    std::atomic<bool> _inuse;
    bool _cached;
    
    std::shared_ptr<std::unordered_map<std::string, int>> _column_names_map;

    friend class Handle;
};
}
#endif /* statement_handle_hpp */
