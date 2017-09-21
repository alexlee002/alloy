//
//  ALDatabase+Config.m
//  alloy
//
//  Created by Alex Lee on 11/09/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDatabase+Config.h"
#import "ALSQLPragma.h"
#import "statement_handle.hpp"
#import "handle.hpp"
#import "error.hpp"
#import "ALUtilitiesHeader.h"
#import "ALDatabase.h"
#import <sqlite3.h>

extern NSString * const kALDBDefaultConfigsName         = @"ALDB_DEFAULT_CONFIG";
extern NSString * const kALDBBusyRetryConfigName        = @"ALDB_BUSY_RETRY_CONFIG";
extern NSString * const kALDBJournalModelConfigName     = @"ALDB_JOURNAL_MODEL_CONFIG";
extern NSString * const kALDBLockingModelConfigName     = @"ALDB_LOCKING_MODEL_CONFIG";
extern NSString * const kALDBSynchronousConfigName      = @"ALDB_SYNCHRONOUS_CONFIG";

@implementation ALDatabase (Config)

+ (const aldb::Configs &)defaultConfigs {
    static const aldb::Configs defaultConfigs({
        {
            kALDBBusyRetryConfigName.UTF8String,
            [self](std::shared_ptr<aldb::Handle> &handle, aldb::ErrorPtr &error) -> bool {
                [self setBusyRetryHandler:handle];
                return true;
            },
            0
        },
        
        {
            kALDBDefaultConfigsName.UTF8String,
            [](std::shared_ptr<aldb::Handle> &handle, aldb::ErrorPtr &error) -> bool {
                return true;
            },
            1
        },
        
        {
            kALDBLockingModelConfigName.UTF8String,
            [self](std::shared_ptr<aldb::Handle> &handle, aldb::ErrorPtr &errorr) -> bool {
                return [self setNormlLockMode:handle];
            },
            1
        },
        {
            kALDBSynchronousConfigName.UTF8String,
            [self](std::shared_ptr<aldb::Handle> &handle, aldb::ErrorPtr &error) -> bool {
                return [self setSynchronous:handle];
            },
            2
        },
        {
            kALDBJournalModelConfigName.UTF8String,
            [self](std::shared_ptr<aldb::Handle> &handle, aldb::ErrorPtr &error) -> bool {
                return [self setWALMode:handle];
            },
            3
        },
    });
    return defaultConfigs;
}

+ (BOOL)setNormlLockMode:(std::shared_ptr<aldb::Handle> &)handle {
    // Get Locking Mode
    static const std::string sGetLockingMode =
        [[[ALSQLPragma statement] pragmaNamed:ALSQLPragmaNameLockingMode] SQLClause].sql_str();
    std::shared_ptr<aldb::StatementHandle> stmt = handle->prepare(sGetLockingMode);
    if (!stmt) {
        ALDB_LOG_ERROR(handle);
        return false;
    }
    stmt->step();
    if (stmt->has_error()) {
        ALLogError(@"%s", stmt->get_error()->description().c_str());
        return false;
    }
    std::string lockingMode = stmt->get_text_value(0);
    stmt->finalize();

    // Set Locking Mode
    static const std::string sSetLockingModeNormal =
        [[[ALSQLPragma statement] setPragma:ALSQLPragmaNameLockingMode value:"NORMAL"] SQLClause].sql_str();
    if (strcasecmp(lockingMode.c_str(), "NORMAL") != 0 && !handle->exec(sSetLockingModeNormal)) {
        ALDB_LOG_ERROR(handle);
        return false;
    }
    return true;
}

+ (BOOL)setSynchronous:(std::shared_ptr<aldb::Handle> &)handle {
    static const std::string sSetSynchronousFull =
        [[[ALSQLPragma statement] setPragma:ALSQLPragmaNameSynchronous value:"NORMAL"] SQLClause].sql_str();

    if (!handle->exec(sSetSynchronousFull)) {
        ALDB_LOG_ERROR(handle);
        return false;
    }
    return true;
}

+ (BOOL)setWALMode:(std::shared_ptr<aldb::Handle> &)handle {
    static const std::string sGetJournalMode =
        [[[ALSQLPragma statement] pragmaNamed:ALSQLPragmaNameJournalMode] SQLClause].sql_str();
    static const std::string sSetJournalModeWAL =
        [[[ALSQLPragma statement] setPragma:ALSQLPragmaNameJournalMode value:"WAL"] SQLClause].sql_str();

    // Get Journal Mode
    std::shared_ptr<aldb::StatementHandle> stmt = handle->prepare(sGetJournalMode);
    if (!stmt) {
        ALDB_LOG_ERROR(handle);
        return false;
    }
    stmt->step();
    if (stmt->has_error()) {
        ALLogError(@"%s", stmt->get_error()->description().c_str());
        return false;
    }
    std::string journalMode = stmt->get_text_value(0);
    stmt->finalize();

    // Set Journal Mode
    if (strcasecmp(journalMode.c_str(), "WAL") != 0 && !handle->exec(sSetJournalModeWAL)) {
        ALDB_LOG_ERROR(handle);
        return false;
    }

    return true;
}

+ (void)setBusyRetryHandler:(std::shared_ptr<aldb::Handle> &)handle {
    handle->register_sqlite_busy_handler([](void *h, int c) -> int {
        sqlite3_sleep((c % 16) * 2 + 2); // 2 ~ 32
        if (c > 256) {
            ALLogWarn(@"Too many attempts to retry: %d, handle: %p", c, h);
            return 0;
        }
        return 1;
    });
}

@end
