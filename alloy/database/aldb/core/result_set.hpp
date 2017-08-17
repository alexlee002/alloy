//
//  result_set.hpp
//  alloy
//
//  Created by Alex Lee on 01/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#ifndef result_set_hpp
#define result_set_hpp

#include <stdio.h>
#include "catchable.hpp"

namespace aldb {
    class StatementHandle;
    class ResultSet: public Catchable {
    public:
        void close();
        
        bool next();
        
        const int32_t get_int32_value(int index);
        const int64_t get_int64_value(int index);
        const double  get_double_value(int index);
        const char *get_text_value(int index);
        const void *get_blob_value(int index);
        
        int column_count() const;
        const char *column_name(int idx) const;
        
    protected:
        ResultSet(std::shared_ptr<aldb::StatementHandle> stmt);
        ResultSet operator=(const ResultSet &) = delete;
//        ResultSet(const ResultSet &) = delete;
        
        std::shared_ptr<aldb::StatementHandle> _stmt;
        
//        const aldb::StatementHandle _stmt;
        
        friend class StatementHandle;
    };
}

#endif /* result_set_hpp */
