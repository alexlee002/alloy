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

#ifndef core_base_hpp
#define core_base_hpp

#include "config.hpp"
#include "defines.hpp"
#include "statement_recyclable.hpp"
#include "sql_statement.hpp"
#include <list>

namespace aldb {

class Database;
class Transaction;
struct SQLValue;

enum class CoreType : int8_t {
    NONE,
    TRANSACTION,
    DATABASE,
};

class CoreBase /*: public Catchable*/ {
  public:
    CoreType get_type() const;

    virtual const std::string &get_path() const = 0;
    // Handle Protocol
    virtual RecyclableStatement prepare(const std::string &sql, ErrorPtr &error) = 0;
    virtual bool exec(const std::string &sql, ErrorPtr &error) = 0;
    virtual bool exec(const std::string &sql, const std::list<const SQLValue> &args, ErrorPtr &error) = 0;
    virtual bool exec(const SQLStatement &sql, ErrorPtr &error) = 0;

    // Transaction Protocol
    enum class TransactionEvent {
        BEGIN_FAILED    = 0,
        COMMIT_FAILED   = 1,
        ROLLBACK        = 2,
        ROLLBACK_FAILED = 3,
    };
    typedef std::function<void(bool &)> TransactionBlock;
    typedef std::function<void(TransactionEvent)> TransactionEventBlock;
    
    virtual bool begin_transaction(const aldb::TransactionMode mode, ErrorPtr &error) = 0;
    virtual bool commit(ErrorPtr &error)   = 0;
    virtual bool rollback(ErrorPtr &error) = 0;
    
    virtual bool exec_transaction(TransactionBlock transaction, TransactionEventBlock event_handle, ErrorPtr &error);

  protected:
    RecyclableStatement prepare(const RecyclableHandle &handle, const std::string &sql, ErrorPtr &error);
    bool exec(const RecyclableHandle &handle, const std::string &sql, ErrorPtr &error);
    bool exec(const RecyclableHandle &handle,
              const std::string &sql,
              const std::list<const SQLValue> &args,
              ErrorPtr &error);
    bool exec(const RecyclableHandle &handle, const SQLStatement &sql, ErrorPtr &error);

    CoreBase(/*const RecyclableHandlePool &pool, */CoreType type);

    const CoreType _type;
    //RecyclableHandlePool _pool;
};

}  // namespace aldb

#endif /* core_base_hpp */
