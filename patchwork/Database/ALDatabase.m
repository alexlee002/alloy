//
//  ALDatabase.m
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALDatabase.h"
#import "NSString+Helper.h"
#import "FMDB.h"
#import "BlocksKit.h"
#import "ALOCRuntime.h"
#import "ALDBMigrationProtocol.h"
#import "ALDBConnectionProtocol.h"
#import "SafeBlocksChain.h"
#import "PatchworkLog_private.h"
#import "ALLock.h"
#import "ALDBMigrationHelper.h"


NS_ASSUME_NONNULL_BEGIN

NSString * const kALInMemoryDBPath = @":memory:";  // in-memory db
NSString * const kALTempDBPath     = @"";          // temp db;


static NSMutableDictionary<NSString *, ALDatabase *>   *kDatabaseDict = nil;

@implementation ALDatabase {
    NSSet<Class>      *_modelClasses;
    BOOL               _dbFileExisted;
    BOOL               _enableDebug;
    id<ALDBConnectionProtocol> _openHelper;
}

#pragma mark - database manager
+ (nullable instancetype)databaseWithPath:(NSString *)path {
    path = stringValue(path);
    if (path == nil) {
        return nil;
    }
    
    __block ALDatabase *db = kDatabaseDict[path];
    if (db == nil) {
        static_gcd_semaphore(localSem, 1);
        with_gcd_semaphore(localSem, DISPATCH_TIME_FOREVER, ^{
            if (kDatabaseDict == nil) {
                kDatabaseDict = [NSMutableDictionary dictionary];
            }
            db = kDatabaseDict[path];
            if (db == nil) {
                // @see "+[FMDatabase databaseWithPath:]",  @"" => temp DB; nil => in-memory DB
                NSString *dbFilePath = path;
                if ([path isEqualToString:kALInMemoryDBPath]) {
                    dbFilePath = nil;
                } else if ([path isEqualToString:kALTempDBPath]) {
                    dbFilePath = @"";
                }
                
                if((db = [(ALDatabase *)[self alloc] initWithPath:dbFilePath]) != nil) {
                    kDatabaseDict[path] = db;
                } else {
                    db = nil;
                }
            }
        });
    }
    return db;
}

- (nullable instancetype)initWithPath:(nullable NSString *)path {
    self = [super init];
    if (self) {
#if DEBUG
        _enableDebug = YES;
#else
        _enableDebug = NO;
#endif
        
        if (!isEmptyString(path)) {
            // for compatible.
            // if the original database existed and did not set the version information,
            // we need to make a distinction between 'database not exists' and 'database version = 0'
            _dbFileExisted = [[NSFileManager defaultManager] fileExistsAtPath:path];

            NSError *tmpError = nil;
            if (![[NSFileManager defaultManager] createDirectoryAtPath:[path stringByDeletingLastPathComponent]
                                           withIntermediateDirectories:YES
                                                            attributes:nil
                                                                 error:&tmpError]) {
                ALLogError(@"Can not create database file:%@; %@", path, tmpError);
                return nil;
            }
        }
        _queue = [[ALFMDatabaseQueue alloc] initWithPath:path];
        if (![self open]) {
            self = nil;
        }
    }
    return self;
}

- (void)dealloc {
    [self close];
}

// To support chain expression syntax, we need to support default -init constructor that we can
// create a "fake" object to avoid crash. -- Think about "nil();".
//- (nullable instancetype)init {
//    return nil;
//}

- (BOOL)open {
    if (_queue == nil) {
        return NO;
    }
    
    id<ALDBMigrationProtocol> migrationProcessor = [self dbMigrationProcessor];
    _openHelper = [self connectionHandler];
    
    __block BOOL ret = YES;
    [_queue inDatabase:^(FMDatabase * _Nonnull db) {
        [db closeOpenResultSets];
        
        // extension point: you can define some specified configs immediately after DB opened。
        if ([_openHelper respondsToSelector:@selector(databaseDidOpen:)]) {
            [_openHelper databaseDidOpen:db];
        }
        
        // database migration
        if (migrationProcessor == nil) {
            _ALDBLog(@"Not found database migration processor, try auto-migration. database path: %@", _queue.path);
            
            if (!_dbFileExisted) {
                [ALDBMigrationHelper setupDatabase:db];
            } else {
                [ALDBMigrationHelper autoMigrateDatabase:db];
            }
            ret = YES;
        } else {
        
            // all the database version should begins from 1 (DO NOT begins from 0 !!!)
            NSInteger newVersion = [migrationProcessor currentVersion];
            
            if (!_dbFileExisted) { // create database directly
                BOOL created = NO;
                if ([migrationProcessor respondsToSelector:@selector(setupDatabase:)]) { // manually setup database
                    created = [migrationProcessor setupDatabase:db];
                } else {
                    [ALDBMigrationHelper setupDatabase:db];
                    created = YES;
                }
                
                if (created) {
                    ret = [self updateDatabaseVersion:newVersion dbHandler:db];
                } else {
                    NSAssert(NO, @"Can not setup database: %@", _queue.path);
                    ret = NO;
                }
            } else {
                NSInteger dbVersion = [db intForQuery:@"PRAGMA user_version;"];

                if (dbVersion < newVersion) {
                    if ([migrationProcessor migrateFromVersion:dbVersion to:newVersion databaseHandler:db]) {
                        ret = [self updateDatabaseVersion:newVersion dbHandler:db];
                    } else {
                        NSAssert(NO, @"migrate from version %@ to %@ failed!!! database: %@", @(dbVersion),
                                 @(newVersion), _queue.path);
                        ret = NO;
                    }
                } else if (dbVersion > newVersion) {
                    NSAssert(NO, @"Illegal database version. original:%@, new version:%@",
                             @(dbVersion), @(newVersion));
                    ret = NO;
                }
            }
        }
        
        // extension point
        if ([_openHelper respondsToSelector:@selector(databaseDidSetup:)]) {
            [_openHelper databaseDidSetup:db];
        }
    }];
    
    return ret;
}

- (BOOL)updateDatabaseVersion:(NSInteger)version dbHandler:(FMDatabase *)db {
    BOOL ret = [db executeUpdate:[NSString stringWithFormat:@"PRAGMA user_version=%ld;", (long)version]];
    if (!ret) {
#if DEBUG
        NSAssert(NO, @"*** update database version to %@ failed\npath: %@\nerror:%@", @(version), _queue.path,
                     [db lastError]);
#endif
        ALLogWarn(@"*** update database version to %@ failed\npath: %@\nerror:%@", @(version), _queue.path,
                      [db lastError]);
    }
    return ret;
}

- (void)close {
    // extension point
    [_queue inDatabase:^(FMDatabase * _Nonnull db) {
        if ([_openHelper respondsToSelector:@selector(databaseWillClose:)]) {
            [_openHelper databaseWillClose:db];
        }
    }];
    
    NSString *path = _queue.path;
    [kDatabaseDict removeObjectForKey:path];
    [_queue close];
    _queue = nil;
    
    // extension point
    if ([_openHelper respondsToSelector:@selector(databaseWithPathDidClose:)]) {
        [_openHelper databaseWithPathDidClose:path];
    }
}

- (id)copy {
    return self;
}

- (id)mutableCopy {
    return self;
}

- (nullable id<ALDBMigrationProtocol>)dbMigrationProcessor {
    Class cls = [[ALOCRuntime classConfirmsToProtocol:@protocol(ALDBMigrationProtocol)] bk_select:^BOOL(Class cls){
        return [cls canMigrateDatabaseWithPath:_queue.path];
    }].anyObject;
    return [[cls alloc] init];
}

- (nullable id<ALDBConnectionProtocol>)connectionHandler {
    Class cls = [[ALOCRuntime classConfirmsToProtocol:@protocol(ALDBConnectionProtocol)] bk_select:^BOOL(Class cls){
        return [cls canHandleDatabaseWithPath:_queue.path];
    }].anyObject;
    return [[cls alloc] init];
}

@end

#define __ALDB_STMT_INIT(stmt_class) \
    stmt_class *stmt = nil;                                             \
    if (ObjIsValidBlocksChainObject(self)) {                            \
        stmt = [stmt_class statementWithDatabase:self];                 \
    }

#define __ALDB_STMT_BLOCK_ID_ARG(stmt_class, block_args, prop_name)         \
- (stmt_class * (^)(id block_args))prop_name {                              \
    return ^stmt_class *(id block_args) {                                   \
        __ALDB_STMT_INIT(stmt_class);                                       \
        return SafeBlocksChainObj(stmt, stmt_class).prop_name(block_args);  \
    };                                                                      \
}

#define __ALDB_STMT_BLOCK(stmt_class, prop_name)                            \
- (stmt_class * (^)())prop_name {                                           \
    return ^stmt_class * {                                                  \
        __ALDB_STMT_INIT(stmt_class);                                       \
        return SafeBlocksChainObj(stmt, stmt_class).prop_name();            \
    };                                                                      \
}

@implementation ALDatabase (ALSQLStatment)

__ALDB_STMT_BLOCK_ID_ARG(ALSQLSelectStatement, columns, SELECT);

__ALDB_STMT_BLOCK_ID_ARG(ALSQLUpdateStatement, tableName, UPDATE);

__ALDB_STMT_BLOCK(ALSQLInsertStatement, INSERT);
__ALDB_STMT_BLOCK(ALSQLInsertStatement, REPLACE);

__ALDB_STMT_BLOCK(ALSQLDeleteStatement, DELETE);

@end

@implementation ALDatabase (ALDebug)

- (void)setEnableDebug:(BOOL)enableDebug {
    _enableDebug = enableDebug;
}

- (BOOL)enableDebug {
    return _enableDebug;
}

@end


NS_ASSUME_NONNULL_END
