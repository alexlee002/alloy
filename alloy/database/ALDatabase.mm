//
//  ALDatabase.m
//  alloy
//
//  Created by Alex Lee on 27/07/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDatabase.h"
#import "ALLock.h"
#import "statement_recyclable.hpp"
#import "database.hpp"
#import "handle_recyclable.hpp"
#import "ALUtilitiesHeader.h"
#import "ALDBConnectionDelegate.h"
#import "ALDBMigrationDelegate.h"
#import "ALDBMigrationHelper.h"
#import "ALOCRuntime.h"
#import <BlocksKit.h>

static AL_FORCE_INLINE NSMutableDictionary<NSString *, ALDatabase *> *KeepAliveDatabases() {
    static NSMutableDictionary<NSString *, ALDatabase *> *dict = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dict = [NSMutableDictionary dictionaryWithCapacity:4];
    });
    return dict;
}

static AL_FORCE_INLINE dispatch_semaphore_t KeepAliveDatabaseSemaphore() {
    static dispatch_semaphore_t dsem;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dsem = dispatch_semaphore_create(1);
    });
    return dsem;
}

@implementation ALDatabase {
    std::shared_ptr<aldb::Database> _coreDB;
    id<ALDBConnectionDelegate> _connectionDelegate;
    
    BOOL _dbFileExisted;
}

+ (nullable instancetype)databaseWithPath:(NSString *)path keepAlive:(BOOL)keepAlive {
    ALDatabase *db = [[ALDatabase alloc] init];
    db->_path = [path copy];
    
    BOOL isDir = NO;
    db->_dbFileExisted = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && !isDir;
    
    std::shared_ptr<aldb::Database> coreDB(
        new aldb::Database([path UTF8String], {}, [db](const aldb::RecyclableHandle &handle) -> bool {
        return [db openDatabaseWithHandle:handle];
    }));
    
    db->_coreDB = coreDB;
    
    if (keepAlive) {
        dispatch_semaphore_t dsem = KeepAliveDatabaseSemaphore();
        dispatch_semaphore_wait(dsem, DISPATCH_TIME_FOREVER);
        KeepAliveDatabases()[path] = db;
        dispatch_semaphore_signal(dsem);
    }
    return db;
}

- (void)close {
    id<ALDBConnectionDelegate> connDelegate = [self connectionDelegate];
    if ([connDelegate respondsToSelector:@selector(willCloseDatabase:)]) {
        [connDelegate willCloseDatabase:self];
    }
    
    _coreDB->close([self, connDelegate](void){
        [KeepAliveDatabases() removeObjectForKey:_path];
        
        if ([connDelegate respondsToSelector:@selector(didCloseDatabase:)]) {
            [connDelegate didCloseDatabase:self];
        }
    });
}

#pragma mark -

- (BOOL)openDatabaseWithHandle:(const aldb::RecyclableHandle)handle {
    if (!handle) {
        return NO;
    }
    //???: close opened statements?
    
    id<ALDBConnectionDelegate> connDelegate = [self connectionDelegate];
    
    // extension point: you can define some specified configs immediately after DB opened.
    if ([connDelegate respondsToSelector:@selector(databaseDidOpen:)]) {
        [connDelegate databaseDidOpen:handle];
    }
    
    // database migration
    if ([self migrateDatabaseUsingHandle:handle]) {
        // extension point: database is ready.
        if ([connDelegate respondsToSelector:@selector(databaseDidReady:)]) {
            [connDelegate databaseDidReady:handle];
        }
        return YES;
    }
    return NO;
}

- (BOOL)migrateDatabaseUsingHandle:(const aldb::RecyclableHandle)handle {
    id<ALDBMigrationDelegate> delegate = [self migrationDelegate];

    if (!_dbFileExisted) {  // create new database

        // automatically create tables and indexes.(for models that return YES in '+autoBindDatabase' )
        [ALDBMigrationHelper setupDatabaseUsingHandle:handle];

        // manually create tables and indexes.(for models that return NO in '+autoBindDatabase' )
        BOOL created = YES;
        if ([delegate respondsToSelector:@selector(setupDatabaseUsingHandle:)]) {
            created = [delegate setupDatabaseUsingHandle:handle];
            al_guard_or_return1(created, NO, @"Can not setup database in path: %@", _path);

            NSInteger newVersion = [delegate currentVersion];
            al_guard_or_return1(newVersion > 0, NO, @"*** Database version must be > 0, but was %d; path: %@",
                                (int) newVersion, _path);
            [self setDatabaseVersion:newVersion usingHandle:handle];
        }
    } else {
        // automatically migrate database schemas(table schema & indexes for models that return YES in
        // '+autoBindDatabase)
        [ALDBMigrationHelper autoMigrateDatabaseUsingHandle:handle];

        // manually migrate database:
        // 1, for models that return YES in '+autoBindDatabase
        // 2, or other updates that can't be automatically migrated.
        if (delegate != nil) {
            NSInteger newVersion = [delegate currentVersion];
            al_guard_or_return1(newVersion > 0, NO, @"*** Database version must be > 0, but was %d; path: %@",
                                (int) newVersion, _path);

            NSInteger dbVersion = [self currentDBVersion:handle];
            if (dbVersion < newVersion) {
                al_guard_or_return1([delegate upgradeFromVersion:dbVersion to:newVersion usingHandle:handle], NO,
                                    @"upgrade database from version %ld to %ld failed!!! path: %@", (long) dbVersion,
                                    (long) newVersion, _path);
            } else if (dbVersion > newVersion) {
                al_guard_or_return1([delegate downgradeFromVersion:dbVersion to:newVersion usingHandle:handle], NO,
                                    @"downgrade database from version %ld to %ld failed!!! path: %@", (long) dbVersion,
                                    (long) newVersion, _path);
            }

            [self setDatabaseVersion:newVersion usingHandle:handle];
        }
    }

    return YES;
}

- (NSInteger)currentDBVersion:(const aldb::RecyclableHandle)handle {
    NSInteger ver = 0;
    std::shared_ptr<aldb::StatementHandle> stmt = handle->prepare("PRAGMA user_version;");
    if (stmt && stmt->step()) {
        ver = stmt->get_int32_value(0);
        stmt->finalize();
    }
    return ver;
}

- (BOOL)setDatabaseVersion:(NSInteger)newVersion usingHandle:(const aldb::RecyclableHandle)handle {
    return handle->exec("PRAGMA user_version = " + std::to_string(newVersion));
}

#pragma mark -
- (nullable id<ALDBMigrationDelegate>)migrationDelegate {
    Class cls = [[ALOCRuntime classConfirmsToProtocol:@protocol(ALDBMigrationDelegate)] bk_select:^BOOL(Class cls) {
                    return [cls canMigrateDatabaseWithPath:_path];
                }].anyObject;
    return [[cls alloc] init];
}

- (nullable id<ALDBConnectionDelegate>)connectionDelegate {
    if (_connectionDelegate == nil) {
        al_static_gcd_semaphore_def(dsem, 1);
        dispatch_semaphore_wait(dsem, DISPATCH_TIME_FOREVER);
        if (_connectionDelegate == nil) {
            Class cls =
                [[ALOCRuntime classConfirmsToProtocol:@protocol(ALDBConnectionDelegate)] bk_select:^BOOL(Class cls) {
                    return [cls canOpenDatabaseWithPath:_path];
                }].anyObject;
            _connectionDelegate = [[cls alloc] init];
        }
        dispatch_semaphore_signal(dsem);
    }
    return _connectionDelegate;
}

#pragma mark 

- (id)copy { return self; }
- (id)mutableCopy { return self; }

- (std::shared_ptr<aldb::Database> &)_coreDB {
    return _coreDB;
}

@end
