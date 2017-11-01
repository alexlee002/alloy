//
//  ALDatabase+Config.m
//  alloy
//
//  Created by Alex Lee on 11/09/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDatabase+Config.h"
#import "ALDatabase_Private.h"
#import "statement_handle.hpp"
#import "database.hpp"
#import "handle.hpp"
#import "config.hpp"
#import "TimedQueue.hpp"
#import "sql_pragma.hpp"
#import "pragma.hpp"
#import "error.hpp"
#import "ALMacros.h"
#import "ALLogger.h"
#import "ALDatabase.h"
#import <sqlite3.h>

NSString *const kALDBDefaultConfigsName          = @"ALDB_DEFAULT_CONFIG";
NSString *const kALDBBusyRetryConfigName         = @"ALDB_BUSY_RETRY_CONFIG";
NSString *const kALDBJournalModeConfigName       = @"ALDB_JOURNAL_MODE_CONFIG";
NSString *const kALDBLockingModeConfigName       = @"ALDB_LOCKING_MODE_CONFIG";
NSString *const kALDBSynchronousConfigName       = @"ALDB_SYNCHRONOUS_CONFIG";
NSString *const kALDBCacheSizeConfigName         = @"ALDB_CACHE_SIZE_CONFIG";
NSString *const kALDBPageSizeConfigName          = @"ALDB_PAGE_SIZE_CONFIG";
NSString *const KALDBDefaultCheckPointConfigName = @"ALDB_DEFAULT_CHECKPOINT_CONFIG";

static int aldb_default_busy_handler(void *h, int c) {
    sqlite3_sleep((c % 16) * 2 + 2);  // 2 ~ 32
    if (c > 256) {
#if DEBUG
        if (c % 5 == 0) {
            ALLogWarn(@"Too many attempts to retry: %d, handle: %p", c, h);
        }
#endif
        sqlite3_sleep(50);
    }
    return 1;
}

@implementation ALDatabase (Config)

- (void)setConfig:(const aldb::Config &)config named:(NSString *)name order:(aldb::Configs::Order)order {
    if (_coreDatabase) {
        _coreDatabase->set_config(name.UTF8String, config, order);
    }
}

- (void)setConfig:(const aldb::Config &)config named:(NSString *)name {
    if (_coreDatabase) {
        _coreDatabase->set_config(name.UTF8String, config);
    }
}

+ (const aldb::Configs &)defaultConfigs {
    static const aldb::Configs defaultConfigs({
        {
            kALDBBusyRetryConfigName.UTF8String,
            [self](std::shared_ptr<aldb::Handle> &handle, aldb::ErrorPtr &error) -> bool {
                handle->register_sqlite_busy_handler(aldb_default_busy_handler);
                return true;
            },
            (aldb::Configs::Order) aldb::Database::ConfigOrder::BUSY_HANDLER,
        },

        {
            kALDBDefaultConfigsName.UTF8String,
            [self](std::shared_ptr<aldb::Handle> &handle, aldb::ErrorPtr &error) -> bool {
                if (![self setLockingMode:"NORMAL" handle:handle]) {
                    return false;
                }
                if (![self setSynchronousMode:"NORMAL" handle:handle]) {
                    return false;
                }
                if (![self setJournalMode:"WAL" handle:handle]) {
                    return false;
                }
                // Fullfsync
                {
                    static const std::string sSetFullFsync =
                        aldb::SQLPragma().pragma(aldb::Pragma::FULLFSYNC, true).sql();
                    if (![self executeSQL:sSetFullFsync handle:handle]) {
                        return false;
                    }
                }
                return true;
            },
            (aldb::Configs::Order) aldb::Database::ConfigOrder::BASE_CONFIG,
        },
        
        // checkpoint
        {
            KALDBDefaultCheckPointConfigName.UTF8String,
            [self](std::shared_ptr<aldb::Handle> &handle, aldb::ErrorPtr &error) -> bool {
                handle->register_wal_commited_hook([](aldb::Handle *handle, sqlite3 *, const char *, int pages) -> int {
                    
                    static aldb::TimedQueue<std::string> sTimedQueue(2000); // delay 2s
                    if (pages > 1000) {
                        sTimedQueue.requeue(handle->get_path());
                    }
                    
                    // background check-point thread
                    static std::thread sCheckPointThread([]() {
                        pthread_setname_np("aldb-default-checkpoint");
                        while (true) {
                            sTimedQueue.wait_until_expired([](const std::string &path) {
                                aldb::Database database(path);
                                aldb::ErrorPtr error;
                                if(!database.exec(aldb::SQLPragma().pragma(aldb::Pragma::WAL_CHECKPOINT), error)) {
                                    ALLogError(@"%s", error->description().c_str());
                                }
                            });
                        }
                    });
                    static std::once_flag s_flag;
                    std::call_once(s_flag, []() { sCheckPointThread.detach(); });
                    return SQLITE_OK;
                }, nullptr);
                return true;
            },
            (aldb::Configs::Order) aldb::Database::ConfigOrder::CHECKPOINT,
        },

        {
            kALDBCacheSizeConfigName.UTF8String,
            [self](std::shared_ptr<aldb::Handle> &handle, aldb::ErrorPtr &error) -> bool {
                return [self setCacheSize:-2000 handle:handle]; // max cache size: 2000 * 1024 bytes
            },
            (aldb::Configs::Order) aldb::Database::ConfigOrder::CACHESIZE,
        },

        {
            kALDBPageSizeConfigName.UTF8String, [self](std::shared_ptr<aldb::Handle> &handle, aldb::ErrorPtr &error)
                                                    -> bool { return [self setPageSize:4096 handle:handle]; },
            (aldb::Configs::Order) aldb::Database::ConfigOrder::PAGESIZE,
        },
    });
    return defaultConfigs;
}

- (void)configBusyRetryHandler:(int (*)(void *, int))busyHandler {
    [self setConfig:[&busyHandler](std::shared_ptr<aldb::Handle> &handle, aldb::ErrorPtr &error) -> bool {
        handle->register_sqlite_busy_handler(busyHandler);
        return true;
    }
              named:kALDBBusyRetryConfigName
              order:(aldb::Configs::Order) aldb::Database::ConfigOrder::BUSY_HANDLER];
}

- (void)configJournalModel:(NSString *)mode {
    std::string modeName = mode.UTF8String;
    [self setConfig:[modeName](std::shared_ptr<aldb::Handle> &handle, aldb::ErrorPtr &error) -> bool {
        return [ALDatabase setJournalMode:modeName handle:handle];
    }
              named:kALDBJournalModeConfigName
              order:(aldb::Configs::Order) aldb::Database::ConfigOrder::JOURNAL_MODE];
}

- (void)configLockingModel:(NSString *)mode {
    std::string modeName = mode.UTF8String;
    [self setConfig:[modeName](std::shared_ptr<aldb::Handle> &handle, aldb::ErrorPtr &error) -> bool {
        return [ALDatabase setLockingMode:modeName handle:handle];
    }
              named:kALDBLockingModeConfigName
              order:(aldb::Configs::Order) aldb::Database::ConfigOrder::LOCKING_MODE];
}

- (void)configSynchronousModel:(NSString *)mode {
    std::string modeName = mode.UTF8String;
    [self setConfig:[modeName](std::shared_ptr<aldb::Handle> &handle, aldb::ErrorPtr &error) -> bool {
        return [ALDatabase setSynchronousMode:modeName handle:handle];
    }
              named:kALDBSynchronousConfigName
              order:(aldb::Configs::Order) aldb::Database::ConfigOrder::SYNCHRONOUS];
}

- (void)configCacheSize:(NSInteger)size {
    [self setConfig:[size](std::shared_ptr<aldb::Handle> &handle, aldb::ErrorPtr &error) -> bool {
        return [ALDatabase setCacheSize:(int) size handle:handle];
    }
              named:kALDBCacheSizeConfigName
              order:(aldb::Configs::Order) aldb::Database::ConfigOrder::CACHESIZE];
}

- (void)configPageSize:(NSInteger)size {
    [self setConfig:[size](std::shared_ptr<aldb::Handle> &handle, aldb::ErrorPtr &error) -> bool {
        return [ALDatabase setPageSize:(int) size handle:handle];
    }
              named:kALDBCacheSizeConfigName
              order:(aldb::Configs::Order) aldb::Database::ConfigOrder::PAGESIZE];
}

//"NORMAL"
+ (BOOL)setLockingMode:(const std::string &)mode handle:(std::shared_ptr<aldb::Handle> &)handle {
    // Get Locking Mode
    static const std::string sGetLockingMode = aldb::SQLPragma().pragma(aldb::Pragma::LOCKING_MODE).sql();
    auto stmt = handle->prepare(sGetLockingMode);
    if (!stmt || handle->has_error()) {
        ALLogError(@"%s", handle->get_error()->description().c_str());
        return false;
    }

    stmt->next_row();
    if (stmt->has_error()) {
        ALLogError(@"%s", stmt->get_error()->description().c_str());
        return false;
    }
    std::string lockingMode = stmt->get_text_value(0);
    stmt->finalize();

    // Set Locking Mode
    if (strcasecmp(lockingMode.c_str(), mode.c_str()) == 0) {
        return true;
    }
    static const std::string sSetLockingMode = aldb::SQLPragma().pragma(aldb::Pragma::LOCKING_MODE, mode).sql();

    return [self executeSQL:sSetLockingMode handle:handle];
}

//"NORMAL"
+ (BOOL)setSynchronousMode:(const std::string &)mode handle:(std::shared_ptr<aldb::Handle> &)handle {
    static const std::string sSetSynchronous = aldb::SQLPragma().pragma(aldb::Pragma::SYNCHRONOUS, mode).sql();
    return [self executeSQL:sSetSynchronous handle:handle];
}

+ (BOOL)setJournalMode:(const std::string &)mode handle:(std::shared_ptr<aldb::Handle> &)handle {
    static const std::string sGetJournalMode = aldb::SQLPragma().pragma(aldb::Pragma::JOURNAL_MODE).sql();

    // Get Journal Mode
    std::shared_ptr<aldb::StatementHandle> stmt = handle->prepare(sGetJournalMode);
    if (!stmt || handle->has_error()) {
        ALLogError(@"%s", handle->get_error()->description().c_str());
        return false;
    }

    stmt->next_row();
    if (stmt->has_error()) {
        ALLogError(@"%s", stmt->get_error()->description().c_str());
        return false;
    }
    std::string journalMode = stmt->get_text_value(0);
    stmt->finalize();

    // Set Journal Mode
    if (strcasecmp(journalMode.c_str(), mode.c_str()) == 0) {
        return true;
    }

    static const std::string sSetJournalMode = aldb::SQLPragma().pragma(aldb::Pragma::JOURNAL_MODE, mode).sql();
    return [self executeSQL:sSetJournalMode handle:handle];
}

+ (BOOL)setCacheSize:(int)size handle:(std::shared_ptr<aldb::Handle> &)handle {
    static const std::string sCacheSizeSQL = aldb::SQLPragma().pragma(aldb::Pragma::CACHE_SIZE, size).sql();
    return [self executeSQL:sCacheSizeSQL handle:handle];
}

+ (BOOL)setPageSize:(int)size handle:(std::shared_ptr<aldb::Handle> &)handle {
    static const std::string sPageSizeSQL = aldb::SQLPragma().pragma(aldb::Pragma::PRAGMA_PAGE_SIZE, size).sql();
    return [self executeSQL:sPageSizeSQL handle:handle];
}

+ (BOOL)executeSQL:(const std::string &)sql handle:(std::shared_ptr<aldb::Handle> &)handle {
    if (!handle->exec(sql)) {
        ALLogError(@"%s", handle->get_error()->description().c_str());
        return false;
    }
    return true;
}
@end
