//
//  ALSQLPragma.m
//  alloy
//
//  Created by Alex Lee on 28/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALSQLPragma.h"
#import "ALSQLExpr.h"

@implementation ALSQLPragma {
    ALSQLClause _clause;
}

- (instancetype)pragmaNamed:(ALSQLPragmaName)pragma {
    ALSQLClause clause;
    clause.append("PRAGMA ").append([self pragmaNameWithPragma:pragma]);
    _clause = clause;
    return self;
}

- (instancetype)setPragma:(ALSQLPragmaName)pragma value:(const ALSQLValue &)value {
    ALSQLClause clause;
    clause.append("PRAGMA ").append(ALSQLExpr([self pragmaNameWithPragma:pragma]) == ALSQLExpr(value));
    _clause = clause;
    return self;
}

- (const ALSQLClause)SQLClause {
    return _clause;
}

- (NSString *)pragmaNameWithPragma:(ALSQLPragmaName)pragma {
    switch (pragma) {
        case ALSQLPragmaNameApplicationId:          return @"application_id";
        case ALSQLPragmaNameAutoVacuum:             return @"auto_vacuum";
        case ALSQLPragmaNameAutomaticIndex:         return @"automatic_index";
        case ALSQLPragmaNameBusyTimeout:            return @"busy_timeout";
        case ALSQLPragmaNameCacheSize:              return @"cache_size";
        case ALSQLPragmaNameCacheSpill:             return @"cache_spill";
        case ALSQLPragmaNameCaseSensitiveLike:      return @"case_sensitive_like";
        case ALSQLPragmaNameCellSizeCheck:          return @"cell_size_check";
        case ALSQLPragmaNameCheckpointFullfsync:    return @"checkpoint_fullfsync";
        case ALSQLPragmaNameCipher:                 return @"cipher";
        case ALSQLPragmaNameCipherAddRandom:        return @"cipher_add_random";
        case ALSQLPragmaNameCipherDefaultKdfIter:   return @"cipher_default_kdf_iter";
        case ALSQLPragmaNameCipherDefaultPageSize:  return @"cipher_default_page_size";
        case ALSQLPragmaNameCipherDefaultUseHmac:   return @"cipher_default_use_hmac";
        case ALSQLPragmaNameCipherMigrate:          return @"cipher_migrate";
        case ALSQLPragmaNameCipherProfile:          return @"cipher_profile";
        case ALSQLPragmaNameCipherProvider:         return @"cipher_provider";
        case ALSQLPragmaNameCipherProviderVersion:  return @"cipher_provider_version";
        case ALSQLPragmaNameCipherUseHmac:          return @"cipher_use_hmac";
        case ALSQLPragmaNameCipherVersion:          return @"cipher_version";
        case ALSQLPragmaNameCipherPageSize:         return @"cipher_page_size";
        case ALSQLPragmaNameCollationList:          return @"collation_list";
        case ALSQLPragmaNameCompileOptions:         return @"compile_options";
        case ALSQLPragmaNameCountChanges:           return @"count_changes";
        case ALSQLPragmaNameDataStoreDirectory:     return @"data_store_directory";
        case ALSQLPragmaNameDataVersion:            return @"data_version";
        case ALSQLPragmaNameDatabaseList:           return @"database_list";
        case ALSQLPragmaNameDefaultCacheSize:       return @"default_cache_size";
        case ALSQLPragmaNameDeferForeignKeys:       return @"defer_foreign_keys";
        case ALSQLPragmaNameEmptyResultCallbacks:   return @"empty_result_callbacks";
        case ALSQLPragmaNameEncoding:               return @"encoding";
        case ALSQLPragmaNameForeignKeyCheck:        return @"foreign_key_check";
        case ALSQLPragmaNameForeignKeyList:         return @"foreign_key_list";
        case ALSQLPragmaNameForeignKeys:            return @"foreign_keys";
        case ALSQLPragmaNameFreelistCount:          return @"freelist_count";
        case ALSQLPragmaNameFullColumnNames:        return @"full_column_names";
        case ALSQLPragmaNameFullfsync:              return @"fullfsync";
        case ALSQLPragmaNameIgnoreCheckConstraints: return @"ignore_check_constraints";
        case ALSQLPragmaNameIncrementalVacuum:      return @"incremental_vacuum";
        case ALSQLPragmaNameIndexInfo:              return @"index_info";
        case ALSQLPragmaNameIndexList:              return @"index_list";
        case ALSQLPragmaNameIndexXinfo:             return @"index_xinfo";
        case ALSQLPragmaNameIntegrityCheck:         return @"integrity_check";
        case ALSQLPragmaNameJournalMode:            return @"journal_mode";
        case ALSQLPragmaNameJournalSizeLimit:       return @"journal_size_limit";
        case ALSQLPragmaNameKey:                    return @"key";
        case ALSQLPragmaNameKdfIter:                return @"kdf_iter";
        case ALSQLPragmaNameLegacyFileFormat:       return @"legacy_file_format";
        case ALSQLPragmaNameLockingMode:            return @"locking_mode";
        case ALSQLPragmaNameMaxPageCount:           return @"max_page_count";
        case ALSQLPragmaNameMmapSize:               return @"mmap_size";
        case ALSQLPragmaNamePageCount:              return @"page_count";
        case ALSQLPragmaNamePageSize:               return @"page_size";
        case ALSQLPragmaNameParserTrace:            return @"parser_trace";
        case ALSQLPragmaNameQueryOnly:              return @"query_only";
        case ALSQLPragmaNameQuickCheck:             return @"quick_check";
        case ALSQLPragmaNameReadUncommitted:        return @"read_uncommitted";
        case ALSQLPragmaNameRecursiveTriggers:      return @"recursive_triggers";
        case ALSQLPragmaNameRekey:                  return @"rekey";
        case ALSQLPragmaNameReverseUnorderedSelects: return @"reverse_unordered_selects";
        case ALSQLPragmaNameSchemaVersion:          return @"schema_version";
        case ALSQLPragmaNameSecureDelete:           return @"secure_delete";
        case ALSQLPragmaNameShortColumnNames:       return @"short_column_names";
        case ALSQLPragmaNameShrinkMemory:           return @"shrink_memory";
        case ALSQLPragmaNameSoftHeapLimit:          return @"soft_heap_limit";
        case ALSQLPragmaNameStats:                  return @"stats";
        case ALSQLPragmaNameSynchronous:            return @"synchronous";
        case ALSQLPragmaNameTableInfo:              return @"table_info";
        case ALSQLPragmaNameTempStore:              return @"temp_store";
        case ALSQLPragmaNameTempStoreDirectory:     return @"temp_store_directory";
        case ALSQLPragmaNameThreads:                return @"threads";
        case ALSQLPragmaNameUserVersion:            return @"user_version";
        case ALSQLPragmaNameVdbeAddoptrace:         return @"vdbe_addoptrace";
        case ALSQLPragmaNameVdbeDebug:              return @"vdbe_debug";
        case ALSQLPragmaNameVdbeListing:            return @"vdbe_listing";
        case ALSQLPragmaNameVdbeTrace:              return @"vdbe_trace";
        case ALSQLPragmaNameWalAutocheckpoint:      return @"wal_autocheckpoint";
        case ALSQLPragmaNameWalCheckpoint:          return @"wal_checkpoint";
        case ALSQLPragmaNameWritableSchema:         return @"writable_schema";
        default: return @"";
    }
}

@end
