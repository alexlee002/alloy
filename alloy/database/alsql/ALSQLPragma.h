//
//  ALSQLPragma.h
//  alloy
//
//  Created by Alex Lee on 28/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALSQLStatement.h"

typedef NS_ENUM(NSInteger, ALSQLPragmaName) {
    ALSQLPragmaNameApplicationId,
    ALSQLPragmaNameAutoVacuum,
    ALSQLPragmaNameAutomaticIndex,
    ALSQLPragmaNameBusyTimeout,
    ALSQLPragmaNameCacheSize,
    ALSQLPragmaNameCacheSpill,
    ALSQLPragmaNameCaseSensitiveLike,
    ALSQLPragmaNameCellSizeCheck,
    ALSQLPragmaNameCheckpointFullfsync,
    ALSQLPragmaNameCipher,
    ALSQLPragmaNameCipherAddRandom,
    ALSQLPragmaNameCipherDefaultKdfIter,
    ALSQLPragmaNameCipherDefaultPageSize,
    ALSQLPragmaNameCipherPageSize,
    ALSQLPragmaNameCipherDefaultUseHmac,
    ALSQLPragmaNameCipherMigrate,
    ALSQLPragmaNameCipherProfile,
    ALSQLPragmaNameCipherProvider,
    ALSQLPragmaNameCipherProviderVersion,
    ALSQLPragmaNameCipherUseHmac,
    ALSQLPragmaNameCipherVersion,
    ALSQLPragmaNameCollationList,
    ALSQLPragmaNameCompileOptions,
    ALSQLPragmaNameCountChanges,
    ALSQLPragmaNameDataStoreDirectory,
    ALSQLPragmaNameDataVersion,
    ALSQLPragmaNameDatabaseList,
    ALSQLPragmaNameDefaultCacheSize,
    ALSQLPragmaNameDeferForeignKeys,
    ALSQLPragmaNameEmptyResultCallbacks,
    ALSQLPragmaNameEncoding,
    ALSQLPragmaNameForeignKeyCheck,
    ALSQLPragmaNameForeignKeyList,
    ALSQLPragmaNameForeignKeys,
    ALSQLPragmaNameFreelistCount,
    ALSQLPragmaNameFullColumnNames,
    ALSQLPragmaNameFullfsync,
    ALSQLPragmaNameIgnoreCheckConstraints,
    ALSQLPragmaNameIncrementalVacuum,
    ALSQLPragmaNameIndexInfo,
    ALSQLPragmaNameIndexList,
    ALSQLPragmaNameIndexXinfo,
    ALSQLPragmaNameIntegrityCheck,
    ALSQLPragmaNameJournalMode,
    ALSQLPragmaNameJournalSizeLimit,
    ALSQLPragmaNameKey,
    ALSQLPragmaNameKdfIter,
    ALSQLPragmaNameLegacyFileFormat,
    ALSQLPragmaNameLockingMode,
    ALSQLPragmaNameMaxPageCount,
    ALSQLPragmaNameMmapSize,
    ALSQLPragmaNamePageCount,
    ALSQLPragmaNamePageSize,
    ALSQLPragmaNameParserTrace,
    ALSQLPragmaNameQueryOnly,
    ALSQLPragmaNameQuickCheck,
    ALSQLPragmaNameReadUncommitted,
    ALSQLPragmaNameRecursiveTriggers,
    ALSQLPragmaNameRekey,
    ALSQLPragmaNameReverseUnorderedSelects,
    ALSQLPragmaNameSchemaVersion,
    ALSQLPragmaNameSecureDelete,
    ALSQLPragmaNameShortColumnNames,
    ALSQLPragmaNameShrinkMemory,
    ALSQLPragmaNameSoftHeapLimit,
    ALSQLPragmaNameStats,
    ALSQLPragmaNameSynchronous,
    ALSQLPragmaNameTableInfo,
    ALSQLPragmaNameTempStore,
    ALSQLPragmaNameTempStoreDirectory,
    ALSQLPragmaNameThreads,
    ALSQLPragmaNameUserVersion,
    ALSQLPragmaNameVdbeAddoptrace,
    ALSQLPragmaNameVdbeDebug,
    ALSQLPragmaNameVdbeListing,
    ALSQLPragmaNameVdbeTrace,
    ALSQLPragmaNameWalAutocheckpoint,
    ALSQLPragmaNameWalCheckpoint,
    ALSQLPragmaNameWritableSchema,
};

@interface ALSQLPragma : ALSQLStatement

- (instancetype)pragmaNamed:(ALSQLPragmaName)pragma;
- (instancetype)setPragma:(ALSQLPragmaName)pragma value:(const ALSQLValue &)value;

@end
