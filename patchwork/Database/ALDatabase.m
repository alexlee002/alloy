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
#import "__patchwork_config.h"
#import "ALLock.h"
#import "ALDBMigrationHelper.h"
#import <sqlite3.h>


NS_ASSUME_NONNULL_BEGIN

NSString * const kALInMemoryDBPath = @":memory:";  // in-memory db
NSString * const kALTempDBPath     = @":temp:";    // temp db;


static AL_FORCE_INLINE NSMutableDictionary<NSString *, ALDatabase *> *openingDatabaseDict() {
    static NSMutableDictionary *dict = nil;

    if (dict == nil) {
        al_static_gcd_semaphore_def(localSem, 1);
        with_gcd_semaphore(localSem, DISPATCH_TIME_FOREVER, ^{
            if (dict == nil) {
                dict = [NSMutableDictionary dictionary];
            }
        });
    }
    return dict;
}

static AL_FORCE_INLINE dispatch_semaphore_t openingDBDictSemaphore() {
    static dispatch_semaphore_t sema = NULL;
    
    if (sema == NULL) {
        al_static_gcd_semaphore_def(localSem, 1);
        with_gcd_semaphore(localSem, DISPATCH_TIME_FOREVER, ^{
            if (sema == NULL) {
                sema = dispatch_semaphore_create(1);
            }
        });
    }
    return sema;
}


@implementation ALDatabase {
    BOOL               _dbFileExisted;
    NSInteger          _openFlags;
    id<ALDBConnectionProtocol> _openHelper;
    
    BOOL               _enableDebug;
    
}

#pragma mark - database manager
+ (nullable instancetype)databaseWithPath:(NSString *)path {
    path = al_stringValue(path);
    if (path == nil) {
        return nil;
    }

    NSString *cachedKey = [self cachedKeyWithPath:path readonly:NO];
    NSMutableDictionary *cacheDict = openingDatabaseDict();
    __block ALDatabase *db = cacheDict[cachedKey];
    if (db == nil) {
        with_gcd_semaphore(openingDBDictSemaphore(), DISPATCH_TIME_FOREVER, ^{
            db = cacheDict[cachedKey];
            if (db == nil) {
                // @see "+[FMDatabase databaseWithPath:]",  @"" => temp DB; nil => in-memory DB
                db = [(ALDatabase *) [self alloc] initWithPath:[self innerDBFilePathWithPath:path]
                                                         flags:SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE];
                if (db != nil) {
                    cacheDict[cachedKey] = db;
                }
            }
        });
    }
    return db;
}

// database opened in readonly mode.
+ (nullable instancetype)readonlyDatabaseWithPath:(NSString *)path {
    NSString *cachedKey = [self cachedKeyWithPath:path readonly:YES];
    __block ALDatabase *readonlyDB = openingDatabaseDict()[cachedKey];
    if (readonlyDB == nil) {
        al_static_gcd_semaphore_def(localSema, 1);
        with_gcd_semaphore(localSema, DISPATCH_TIME_FOREVER, ^{
            readonlyDB = openingDatabaseDict()[cachedKey];
            if (readonlyDB != nil) {
                return;
            }
            
            BOOL isDir = NO;
            if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && !isDir) {
                if ([self databaseWithPath:path]) { // make sure to create & migrate database
                    readonlyDB = [(ALDatabase *)[self alloc] initWithPath:[self innerDBFilePathWithPath:path]
                                                                    flags:SQLITE_OPEN_READONLY];
                    if (readonlyDB != nil) {
                        with_gcd_semaphore(openingDBDictSemaphore(), DISPATCH_TIME_FOREVER, ^{
                            openingDatabaseDict()[cachedKey] = readonlyDB;
                        });
                    }
                }
            } else {
                // database not yet created, ignore.
                readonlyDB = nil;
                return;
            }
        });
    }
    return readonlyDB;
}

// database opened in readonly mode, and bind to caller's thread local
+ (nullable instancetype)threadLocalReadonlyDatabaseWithPath:(NSString *)path {
    NSMutableDictionary *dict = [NSThread currentThread].threadDictionary;
    NSString *cachedKey = [self cachedKeyWithPath:path readonly:YES];
    cachedKey = [@"ALDatabase:" stringByAppendingString:cachedKey];
    __block ALDatabase *localReadonlyDB = dict[cachedKey];
    if (localReadonlyDB == nil) {
        al_static_gcd_semaphore_def(localSema, 1);
        with_gcd_semaphore(localSema, DISPATCH_TIME_FOREVER, ^{
            localReadonlyDB = dict[cachedKey];
            if (localReadonlyDB != nil) {
                return;
            }
            
            BOOL isDir = NO;
            if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && !isDir) {
                if ([self databaseWithPath:path]) { // make sure to create & migrate database
                    localReadonlyDB = [(ALDatabase *)[self alloc] initWithPath:[self innerDBFilePathWithPath:path]
                                                                         flags:SQLITE_OPEN_READONLY];
                    if (localReadonlyDB != nil) {
                        dict[cachedKey] = localReadonlyDB;
                    }
                }
            } else {
                // database not yet created, ignore.
                localReadonlyDB = nil;
                return;
            }
        });
    }
    return localReadonlyDB;
}

// openFlag: SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE
- (nullable instancetype)initWithPath:(nullable NSString *)path flags:(int)openFlags{
    
    if (!al_isEmptyString(path)) {

        NSError *tmpError = nil;
        if (![[NSFileManager defaultManager] createDirectoryAtPath:[path stringByDeletingLastPathComponent]
                                       withIntermediateDirectories:YES
                                                        attributes:nil
                                                             error:&tmpError]) {
            ALLogError(@"Can not create database file:%@; %@", path, tmpError);
            return nil;
        }
    }
    
    
    self = [super init];
    if (self) {
#if DEBUG
        _enableDebug = YES;
#else
        _enableDebug = NO;
#endif
        // for compatible.
        // if the original database existed and did not set the version information,
        // we need to make a distinction between 'database not exists' and 'database version = 0'
        _dbFileExisted = [[NSFileManager defaultManager] fileExistsAtPath:path];
        
        _queue = [[ALFMDatabaseQueue alloc] initWithPath:path flags:openFlags];
        if (![self open]) {
            ALLogError(@"Open database error or migrate database failed. path: %@", path);
            self = nil;
        }
        _openFlags = openFlags;
        _openHelper = [self connectionHandler];
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


- (BOOL)isReadonly {
    return (_openFlags & SQLITE_OPEN_READONLY) == SQLITE_OPEN_READONLY;
}

+ (NSString *)innerDBFilePathWithPath:(NSString *)path {
    NSString *dbFilePath = path;
    if ([path isEqualToString:kALInMemoryDBPath]) {
        dbFilePath = nil;
    } else if ([path isEqualToString:kALTempDBPath]) {
        dbFilePath = @"";
    }
    return dbFilePath;
}

+ (NSString *)cachedKeyWithPath:(NSString *)path readonly:(BOOL)readonly {
    NSParameterAssert(path != nil);
    
    NSString *key = al_stringOrEmpty(path);
    if (readonly) {
        key = [key stringByAppendingString:@"#readonly"];
    }
    return key;
}

- (NSString *)cachedKey {
    return [self.class cachedKeyWithPath:_queue.path readonly:self.readonly];
}

- (BOOL)open {
    if (_queue == nil) {
        return NO;
    }
    
    __block BOOL ret = YES;
    [_queue inDatabase:^(FMDatabase * _Nonnull db) {
        [db closeOpenResultSets];
        
        // extension point: you can define some specified configs immediately after DB opened。
        if ([_openHelper respondsToSelector:@selector(databaseDidOpen:)]) {
            [_openHelper databaseDidOpen:db];
        }
        
        // database migration
        if (![self isReadonly]) {
            ret = [self migrateDatabase:db];
        }
        
        // extension point
        if ([_openHelper respondsToSelector:@selector(databaseDidReady:)]) {
            [_openHelper databaseDidReady:db];
        }
    }];
    
    return ret;
}

- (BOOL)migrateDatabase:(FMDatabase *)db {
    id<ALDBMigrationProtocol> migrationProcessor = [self dbMigrationProcessor];
    
    if (migrationProcessor == nil) {
        _ALDBLog(@"Not found database migration processor, try auto-migration. database path: %@", _queue.path);
        
        if (!_dbFileExisted) {
            [ALDBMigrationHelper setupDatabase:db];
        } else {
            [ALDBMigrationHelper autoMigrateDatabase:db];
        }
        return YES;
    } else {
        
        // all the database version should begins from 1 (DO NOT begins from 0 !!!)
        NSInteger newVersion = [migrationProcessor currentVersion];
        al_guard_or_return1(newVersion > 0, NO, @"*** Database version must be > 0, but was %d", (int)newVersion);

        if (!_dbFileExisted) { // create database directly
            BOOL created = NO;
            if ([migrationProcessor respondsToSelector:@selector(setupDatabase:)]) { // manually setup database
                created = [migrationProcessor setupDatabase:db];
            } else {
                [ALDBMigrationHelper setupDatabase:db];
                created = YES;
            }
            
            al_guard_or_return1(created, NO, @"Can not setup database at path: %@", _queue.path);
            return [self updateDatabaseVersion:newVersion dbHandler:db];
        } else {
            NSInteger dbVersion = [db intForQuery:@"PRAGMA user_version;"];
            
            if (dbVersion < newVersion) {
                if (![migrationProcessor database:db upgradeFromVersion:dbVersion to:newVersion] ) {
                    ALAssert(NO, @"migrate from version %@ to %@ failed!!! database: %@", @(dbVersion),
                             @(newVersion), _queue.path);
                    return NO;
                }
                return [self updateDatabaseVersion:newVersion dbHandler:db];
            } else if (dbVersion > newVersion) {
                if (![migrationProcessor database:db downgradeFromVersion:dbVersion to:newVersion] ) {
                    ALAssert(NO, @"migrate from version %@ to %@ failed!!! database: %@", @(dbVersion),
                             @(newVersion), _queue.path);
                    return NO;
                }
                return [self updateDatabaseVersion:newVersion dbHandler:db];
            }
        }
    }
    return YES;
}

- (BOOL)updateDatabaseVersion:(NSInteger)version dbHandler:(FMDatabase *)db {
    return [ALDBMigrationHelper executeSQL:[NSString stringWithFormat:@"PRAGMA user_version=%ld;", (long)version]
                                  database:db];
}

- (void)close {
    if (_queue == nil) {
        return;
    }
    
    with_gcd_semaphore(openingDBDictSemaphore(), DISPATCH_TIME_FOREVER, ^{
        if (_queue == nil) {
            return;
        }
        
        // extension point
        [_queue inDatabase:^(FMDatabase * _Nonnull db) {
            if ([_openHelper respondsToSelector:@selector(databaseWillClose:)]) {
                [_openHelper databaseWillClose:db];
            }
        }];
        
        NSString *key = [self cachedKey];
        if (key != nil) {
            [openingDatabaseDict() removeObjectForKey:key];
        }
        [_queue close];
        
        // extension point
        if ([_openHelper respondsToSelector:@selector(databaseWithPathDidClose:)]) {
            [_openHelper databaseWithPathDidClose:_queue.path];
        }
        
        _queue = nil;
    });
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
    if (al_objIsValidBlocksChainObject(self)) {                         \
        stmt = [stmt_class statementWithDatabase:self];                 \
    }

#define __ALDB_STMT_BLOCK_ID_ARG(stmt_class, block_args, prop_name)         \
- (stmt_class * (^)(id block_args))prop_name {                              \
    return ^stmt_class *(id block_args) {                                   \
        __ALDB_STMT_INIT(stmt_class);                                       \
        return al_safeBlocksChainObj(stmt, stmt_class).prop_name(block_args);  \
    };                                                                      \
}

#define __ALDB_STMT_BLOCK(stmt_class, prop_name)                            \
- (stmt_class * (^)())prop_name {                                           \
    return ^stmt_class * {                                                  \
        __ALDB_STMT_INIT(stmt_class);                                       \
        return al_safeBlocksChainObj(stmt, stmt_class).prop_name();         \
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
