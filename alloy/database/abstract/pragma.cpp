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

#include "pragma.hpp"

namespace aldb {

const Pragma Pragma::APPLICATION_ID("application_id");
const Pragma Pragma::AUTO_VACUUM("auto_vacuum");
const Pragma Pragma::AUTOMATIC_INDEX("automatic_index");
const Pragma Pragma::BUSY_TIMEOUT("busy_timeout");
const Pragma Pragma::CACHE_SIZE("cache_size");
const Pragma Pragma::CACHE_SPILL("cache_spill");
const Pragma Pragma::CASE_SENSITIVE_LIKE("case_sensitive_like");
const Pragma Pragma::CELL_SIZE_CHECK("cell_size_check");
const Pragma Pragma::CHECKPOINT_FULLFSYNC("checkpoint_fullfsync");
const Pragma Pragma::CIPHER("cipher");
const Pragma Pragma::CIPHER_ADD_RANDOM("cipher_add_random");
const Pragma Pragma::CIPHER_DEFAULT_KDF_ITER("cipher_default_kdf_iter");
const Pragma Pragma::CIPHER_DEFAULT_PAGE_SIZE("cipher_default_page_size");
const Pragma Pragma::CIPHER_DEFAULT_USE_HMAC("cipher_default_use_hmac");
const Pragma Pragma::CIPHER_MIGRATE("cipher_migrate");
const Pragma Pragma::CIPHER_PROFILE("cipher_profile");
const Pragma Pragma::CIPHER_PROVIDER("cipher_provider");
const Pragma Pragma::CIPHER_PROVIDER_VERSION("cipher_provider_version");
const Pragma Pragma::CIPHER_USE_HMAC("cipher_use_hmac");
const Pragma Pragma::CIPHER_VERSION("cipher_version");
const Pragma Pragma::CIPHER_PAGE_SIZE("cipher_page_size");
const Pragma Pragma::COLLATION_LIST("collation_list");
const Pragma Pragma::COMPILE_OPTIONS("compile_options");
const Pragma Pragma::COUNT_CHANGES("count_changes");
const Pragma Pragma::DATA_STORE_DIRECTORY("data_store_directory");
const Pragma Pragma::DATA_VERSION("data_version");
const Pragma Pragma::DATABASE_LIST("database_list");
const Pragma Pragma::DEFAULT_CACHE_SIZE("default_cache_size");
const Pragma Pragma::DEFER_FOREIGN_KEYS("defer_foreign_keys");
const Pragma Pragma::EMPTY_RESULT_CALLBACKS("empty_result_callbacks");
const Pragma Pragma::ENCODING("encoding");
const Pragma Pragma::FOREIGN_KEY_CHECK("foreign_key_check");
const Pragma Pragma::FOREIGN_KEY_LIST("foreign_key_list");
const Pragma Pragma::FOREIGN_KEYS("foreign_keys");
const Pragma Pragma::FREELIST_COUNT("freelist_count");
const Pragma Pragma::FULL_COLUMN_NAMES("full_column_names");
const Pragma Pragma::FULLFSYNC("fullfsync");
const Pragma Pragma::IGNORE_CHECK_CONSTRAINTS("ignore_check_constraints");
const Pragma Pragma::INCREMENTAL_VACUUM("incremental_vacuum");
const Pragma Pragma::INDEX_INFO("index_info");
const Pragma Pragma::INDEX_LIST("index_list");
const Pragma Pragma::INDEX_XINFO("index_xinfo");
const Pragma Pragma::INTEGRITY_CHECK("integrity_check");
const Pragma Pragma::JOURNAL_MODE("journal_mode");
const Pragma Pragma::JOURNAL_SIZE_LIMIT("journal_size_limit");
const Pragma Pragma::KEY("key");
const Pragma Pragma::KDF_ITER("kdf_iter");
const Pragma Pragma::LEGACY_FILE_FORMAT("legacy_file_format");
const Pragma Pragma::LOCKING_MODE("locking_mode");
const Pragma Pragma::MAX_PAGE_COUNT("max_page_count");
const Pragma Pragma::MMAP_SIZE("mmap_size");
const Pragma Pragma::PAGE_COUNT("page_count");
const Pragma Pragma::PRAGMA_PAGE_SIZE("page_size");
const Pragma Pragma::PARSER_TRACE("parser_trace");
const Pragma Pragma::QUERY_ONLY("query_only");
const Pragma Pragma::QUICK_CHECK("quick_check");
const Pragma Pragma::READ_UNCOMMITTED("read_uncommitted");
const Pragma Pragma::RECURSIVE_TRIGGERS("recursive_triggers");
const Pragma Pragma::REKEY("rekey");
const Pragma Pragma::REVERSE_UNORDERED_SELECTS("reverse_unordered_selects");
const Pragma Pragma::SCHEMA_VERSION("schema_version");
const Pragma Pragma::SECURE_DELETE("secure_delete");
const Pragma Pragma::SHORT_COLUMN_NAMES("short_column_names");
const Pragma Pragma::SHRINK_MEMORY("shrink_memory");
const Pragma Pragma::SOFT_HEAP_LIMIT("soft_heap_limit");
const Pragma Pragma::STATS("stats");
const Pragma Pragma::SYNCHRONOUS("synchronous");
const Pragma Pragma::TABLE_INFO("table_info");
const Pragma Pragma::TEMP_STORE("temp_store");
const Pragma Pragma::TEMP_STORE_DIRECTORY("temp_store_directory");
const Pragma Pragma::THREADS("threads");
const Pragma Pragma::USER_VERSION("user_version");
const Pragma Pragma::VDBE_ADDOPTRACE("vdbe_addoptrace");
const Pragma Pragma::VDBE_DEBUG("vdbe_debug");
const Pragma Pragma::VDBE_LISTING("vdbe_listing");
const Pragma Pragma::VDBE_TRACE("vdbe_trace");
const Pragma Pragma::WAL_AUTOCHECKPOINT("wal_autocheckpoint");
const Pragma Pragma::WAL_CHECKPOINT("wal_checkpoint");
const Pragma Pragma::WRITABLE_SCHEMA("writable_schema");

Pragma::Pragma(const char *name) : SQLClause(name) {}

const std::string &Pragma::name() const { return sql(); }

}  // namespace aldb
