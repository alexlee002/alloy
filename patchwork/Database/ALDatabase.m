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
#import "UtilitiesHeader.h"
#import "ALModel.h"
#import "ALSQLSelectStatement.h"
#import "ALSQLUpdateStatement.h"
#import "ALSQLInsertStatement.h"
#import "ALOCRuntime.h"
#import "ALDBMigrationProtocol.h"
#import "ALDBConnectionProtocol.h"
#import "SafeBlocksChain.h"
#import "NSCache+ALExtensions.h"

#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

static FORCE_INLINE BOOL hasClassMethod(Class cls, NSString *name);

static NSMutableDictionary<NSString *, ALDatabase *>   *kDatabaseDict = nil;

@implementation ALDatabase {
    NSSet<Class>      *_modelClasses;
    BOOL               _dbFileExisted;
}

#pragma mark - database manager
+ (nullable instancetype)databaseWithPath:(NSString *)path {
    path = [path stringify];
    if (path == nil) {
        return nil;
    }
    
    static dispatch_semaphore_t lock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lock = dispatch_semaphore_create(1);
    });
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    
    if (kDatabaseDict == nil) {
        kDatabaseDict = [NSMutableDictionary dictionary];
    }
    ALDatabase *db = kDatabaseDict[path];
    if (db == nil) {
        if((db = [[self alloc] initWithPath:path]) != nil) {
            kDatabaseDict[path] = db;
        } else {
            db = nil;
        }
    }
    dispatch_semaphore_signal(lock);
    return db;
}

- (nullable instancetype)initWithPath:(nullable NSString *)path {
    self = [super init];
    if (self) {
        // for compatible.
        // if the original database existed and did not set the version information,
        // we need to make a distinction between 'database not exists' and 'database version = 0'
        _dbFileExisted = [[NSFileManager defaultManager] fileExistsAtPath:path];
        _queue = [[ALFMDatabaseQueue alloc] initWithPath:path];
        if (![self open]) {
            self = nil;
        }
    }
    return self;
}

// To support chain expression syntax, we need to support default -init constructor that we can
// create a "fake" object to avoid crash. -- Think about "nil();".
//- (nullable instancetype)init {
//    return nil;
//}

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

- (void)autoSetupDatabase:(FMDatabase *)db {
    NSSet *objTables = [self modelClasses];
    if (objTables.count == 0) {
        ALLogWarn(@"*** Not found any object store in database:%@", _queue.path);
        return;
    }
    
    [objTables bk_each:^(Class cls) {
        [db executeUpdate:[cls tableSchema]];
        [[cls indexStatements] bk_each:^(NSString *sql) {
            [db executeUpdate:sql];
        }];
    }];
}

- (BOOL)open {
    if (_queue == nil) {
        return NO;
    }
    
    id<ALDBMigrationProtocol> migrationProcessor = [self dbMigrationProcessor];
    id<ALDBConnectionProtocol> openHelper = [self connectionHandler];
    
    __block BOOL ret = YES;
    [_queue inDatabase:^(FMDatabase * _Nonnull db) {
        [db closeOpenResultSets];
        
        // extension point: you can define some specified configs immediately after DB opened。
        if ([openHelper respondsToSelector:@selector(databaseDidOpen:)]) {
            [openHelper databaseDidOpen:db];
        }
        
        // database migration
        if (migrationProcessor == nil) {
            ALLogWarn(@"*** Not found any migration processor for database:%@", _queue.path);
            
            [self autoSetupDatabase:db];
            ret = YES;
        } else {
        
            // all the database version should begins from 1 (DO NOT begins from 0 !!!)
            NSInteger newVersion = [migrationProcessor currentVersion];
            if (!_dbFileExisted) { // create database directly
                BOOL created = NO;
                if ([migrationProcessor respondsToSelector:@selector(setupDatabase:)]) { // manually setup database
                    created = [migrationProcessor setupDatabase:db];
                } else {
                    [self autoSetupDatabase:db];
                    created = YES;
                }
                
                if (created) {
                    ret = [self updateDatabaseVersion:newVersion dbHandler:db assertIfFailed:YES];
                } else {
                    NSAssert(NO, @"Can not setup database: %@", _queue.path);
                    ret = NO;
                }
            } else {
                NSInteger dbVersion = [db intForQuery:@"PRAGMA user_version;"];
                NSAssert(dbVersion <= newVersion, @"Illegal database version. original:%@, new version:%@", @(dbVersion),
                         @(newVersion));
                
                if (dbVersion < newVersion) {
                    if ([migrationProcessor migrateFromVersion:dbVersion to:newVersion databaseHandler:db]) {
                        ret = [self updateDatabaseVersion:newVersion dbHandler:db assertIfFailed:YES];
                    } else {
                        NSAssert(NO, @"migrate from version %@ to %@ failed!!! database: %@", @(dbVersion), @(newVersion),
                                 _queue.path);
                        ret = NO;
                    }
                }
            }
        }
        
        // extension point
        if ([openHelper respondsToSelector:@selector(databaseDidSetup:)]) {
            [openHelper databaseDidSetup:db];
        }
    }];
    
    return ret;
}

- (BOOL)updateDatabaseVersion:(NSInteger)version dbHandler:(FMDatabase *)db assertIfFailed:(BOOL)throwAssert {
    BOOL ret = [db executeUpdate:[NSString stringWithFormat:@"PRAGMA user_version=%ld;", version]];
    if (!ret) {
        if (throwAssert) {
            NSAssert(NO, @"*** update database version to %@ failed\npath: %@\nerror:%@", @(version), _queue.path,
                     [db lastError]);
        } else {
            ALLogWarn(@"*** update database version to %@ failed\npath: %@\nerror:%@", @(version), _queue.path,
                      [db lastError]);
        }
    }
    return ret;
}

- (void)close {
    [kDatabaseDict removeObjectForKey:_queue.path];
    [_queue close];
}



- (NSSet<Class> *)modelClasses {
    if (_modelClasses != nil) {
        return _modelClasses;
    }
    
    _modelClasses = [[ALOCRuntime subClassesOf:[ALModel class]] bk_select:^BOOL(Class cls) {
        Class metacls = objc_getMetaClass(object_getClassName(cls));
        NSString *name = NSStringFromSelector(@selector(databaseIdentifier));
        return hasClassMethod(metacls, name) && [[cls databaseIdentifier] isEqualToString:_queue.path];
    }];
    
    return _modelClasses;
}

#pragma mark - database operations
//- (ALSQLSelectBlock)SELECT {
//    return ^ALSQLSelectCommand *_Nonnull (NSArray<NSString *> *_Nullable columns) {
//        if (isValidChainingObject(self)) {
//            return [ALSQLSelectCommand commandWithDatabase:self].SELECT(columns);
//        }
//        return SafeBlocksChainObj(nil, ALSQLSelectCommand);
//    };
//}
//
//- (ALSQLUpdateBlock)UPDATE {
//    return ^ALSQLUpdateCommand *_Nonnull(NSString *_Nonnull table) {
//        if (isValidChainingObject(self)) {
//            return [ALSQLUpdateCommand commandWithDatabase:self].UPDATE(table);
//        }
//        return SafeBlocksChainObj(nil, ALSQLUpdateCommand);
//    };
//}
//
//- (ALSQLInsertBlock)INSERT {
//    return ^ALSQLInsertCommand *_Nonnull(NSString *_Nonnull table) {
//        if (isValidChainingObject(self)) {
//            return [ALSQLInsertCommand commandWithDatabase:self].INSERT(table);
//        }
//        return SafeBlocksChainObj(nil, ALSQLInsertCommand);
//    };
//}
//
//- (ALSQLDeleteBlock)DELETE_FROM {
//    return ^ALSQLDeleteCommand *_Nonnull(NSString *_Nonnull table) {
//        if (isValidChainingObject(self)) {
//            return [ALSQLDeleteCommand commandWithDatabase:self].DELETE_FROM(table);
//        }
//        return SafeBlocksChainObj(nil, ALSQLDeleteCommand);
//    };
//}

@end


FORCE_INLINE BOOL hasClassMethod(Class cls, NSString *name){
    BOOL found = NO;
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(cls, &methodCount);
    if (methods) {
        for (unsigned int i = 0; i < methodCount; i++) {
            SEL sel = method_getName(methods[i]);
            NSString *methodName = [NSString stringWithUTF8String:sel_getName(sel)];
            if ([methodName isEqualToString:name]) {
                found =  YES;
                break;
            }
        }
        free(methods);
    }
    return found;
}

NS_ASSUME_NONNULL_END
