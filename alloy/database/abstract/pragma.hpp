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

#ifndef pragma_hpp
#define pragma_hpp

#include "sql_clause.hpp"

namespace aldb {

class Pragma : public SQLClause {
  public:
    static const Pragma APPLICATION_ID;
    static const Pragma AUTO_VACUUM;
    static const Pragma AUTOMATIC_INDEX;
    static const Pragma BUSY_TIMEOUT;
    static const Pragma CACHE_SIZE;
    static const Pragma CACHE_SPILL;
    static const Pragma CASE_SENSITIVE_LIKE;
    static const Pragma CELL_SIZE_CHECK;
    static const Pragma CHECKPOINT_FULLFSYNC;
    static const Pragma CIPHER;
    static const Pragma CIPHER_ADD_RANDOM;
    static const Pragma CIPHER_DEFAULT_KDF_ITER;
    static const Pragma CIPHER_DEFAULT_PAGE_SIZE;
    static const Pragma CIPHER_DEFAULT_USE_HMAC;
    static const Pragma CIPHER_MIGRATE;
    static const Pragma CIPHER_PROFILE;
    static const Pragma CIPHER_PROVIDER;
    static const Pragma CIPHER_PROVIDER_VERSION;
    static const Pragma CIPHER_USE_HMAC;
    static const Pragma CIPHER_VERSION;
    static const Pragma CIPHER_PAGE_SIZE;
    static const Pragma COLLATION_LIST;
    static const Pragma COMPILE_OPTIONS;
    static const Pragma COUNT_CHANGES;
    static const Pragma DATA_STORE_DIRECTORY;
    static const Pragma DATA_VERSION;
    static const Pragma DATABASE_LIST;
    static const Pragma DEFAULT_CACHE_SIZE;
    static const Pragma DEFER_FOREIGN_KEYS;
    static const Pragma EMPTY_RESULT_CALLBACKS;
    static const Pragma ENCODING;
    static const Pragma FOREIGN_KEY_CHECK;
    static const Pragma FOREIGN_KEY_LIST;
    static const Pragma FOREIGN_KEYS;
    static const Pragma FREELIST_COUNT;
    static const Pragma FULL_COLUMN_NAMES;
    static const Pragma FULLFSYNC;
    static const Pragma IGNORE_CHECK_CONSTRAINTS;
    static const Pragma INCREMENTAL_VACUUM;
    static const Pragma INDEX_INFO;
    static const Pragma INDEX_LIST;
    static const Pragma INDEX_XINFO;
    static const Pragma INTEGRITY_CHECK;
    static const Pragma JOURNAL_MODE;
    static const Pragma JOURNAL_SIZE_LIMIT;
    static const Pragma KEY;
    static const Pragma KDF_ITER;
    static const Pragma LEGACY_FILE_FORMAT;
    static const Pragma LOCKING_MODE;
    static const Pragma MAX_PAGE_COUNT;
    static const Pragma MMAP_SIZE;
    static const Pragma PAGE_COUNT;
    static const Pragma PRAGMA_PAGE_SIZE;
    static const Pragma PARSER_TRACE;
    static const Pragma QUERY_ONLY;
    static const Pragma QUICK_CHECK;
    static const Pragma READ_UNCOMMITTED;
    static const Pragma RECURSIVE_TRIGGERS;
    static const Pragma REKEY;
    static const Pragma REVERSE_UNORDERED_SELECTS;
    static const Pragma SCHEMA_VERSION;
    static const Pragma SECURE_DELETE;
    static const Pragma SHORT_COLUMN_NAMES;
    static const Pragma SHRINK_MEMORY;
    static const Pragma SOFT_HEAP_LIMIT;
    static const Pragma STATS;
    static const Pragma SYNCHRONOUS;
    static const Pragma TABLE_INFO;
    static const Pragma TEMP_STORE;
    static const Pragma TEMP_STORE_DIRECTORY;
    static const Pragma THREADS;
    static const Pragma USER_VERSION;
    static const Pragma VDBE_ADDOPTRACE;
    static const Pragma VDBE_DEBUG;
    static const Pragma VDBE_LISTING;
    static const Pragma VDBE_TRACE;
    static const Pragma WAL_AUTOCHECKPOINT;
    static const Pragma WAL_CHECKPOINT;
    static const Pragma WRITABLE_SCHEMA;

    const std::string &name() const;

  protected:
    Pragma(const char *name);
};

} //namespace aldb

#endif /* pragma_hpp */
