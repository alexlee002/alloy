//
//  statement_handle.hpp
//  alloy
//
//  Created by Alex Lee on 23/07/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#ifndef statement_handle_hpp
#define statement_handle_hpp

#include <stdio.h>
#include <string>
#include "catchable.hpp"
#include "defines.hpp"

namespace aldb {
    class SQLValue;
    class Handle;
    class Error;
    class ResultSet;
    
    class StatementHandle : public Catchable {
    public:
        virtual ~StatementHandle();
        void finalize();
        
        bool step();
        bool reset_bindings();
        bool bind_value(const SQLValue &value, const int index);
        
        const int32_t get_int32_value(int index);
        const int64_t get_int64_value(int index);
        const double get_double_value(int index);
        const char *get_text_value(int index);
        const void *get_blob_value(int index, size_t &size);
        
        int column_count() const;
        const char *column_name(int idx) const;
        ColumnType column_type(int idx) const;
        
//        const aldb::ResultSet result_set();
//        operator aldb::ResultSet() const;
        
//        __uint64_t threadid;
        
    protected:
        StatementHandle(const Handle &handle, void *stmt);
        const StatementHandle &operator=(const StatementHandle &other) = delete;
        StatementHandle(const StatementHandle &other) = delete;
        
        const Handle &_hadler;
        void *_stmt;
        
        std::atomic<bool> _inuse;
        bool _cached;
        
        friend class Handle;
        friend class ResultSet;
    };
}
#endif /* statement_handle_hpp */
