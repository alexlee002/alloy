//
//  ALDatabase.m
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALDatabase.h"
#import "StringHelper.h"
#import "FMDB.h"
#import "ALDatabaseModelProtocol.h"
#import "BlocksKit.h"
#import "UtilitiesHeader.h"
#import "ALSQLSelectCommand.h"
#import "ALSQLUpdateCommand.h"
#import "ALSQLInsertCommand.h"
#import "ALOCRuntime.h"
#import "ALDBMigrationProtocol.h"

#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN



static NSMutableDictionary<NSString *, ALDatabase *>   *kDatabaseDict = nil;

@implementation ALDatabase {
    NSSet<Class>      *_tableModels;
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
        _database = [[ALFMDatabaseQueue alloc] initWithPath:path];
        if (![self open]) {
            self = nil;
        }
    }
    return self;
}

- (nullable instancetype)init {
    NSAssert(NO, @"Not supported!");
    return nil;
}

- (id)copy {
    return self;
}

- (id)mutableCopy {
    return self;
}

- (BOOL)open {
    if (_database == nil) {
        return NO;
    }
    
    NSSet *objTables = [self tableModels];
    if (objTables.count == 0) {
        ALLogWarn(@"*** Not found any object store in database:%@", _database.path);
        return YES;
    }
    
    id<ALDBMigrationProtocol> migrationProcessor =
        [[ALOCRuntime classConfirmsToProtocol:@protocol(ALDBMigrationProtocol)] bk_select:^BOOL(Class cls){
            return [cls canMigrateDatabaseWithPath:_database.path];
        }].anyObject;
    
    if (migrationProcessor == nil) {
        ALLogWarn(@"*** Not found any migration processor for database:%@", _database.path);
        return YES;
    }
    
    __block BOOL ret = YES;
    [_database inDatabase:^(FMDatabase * _Nonnull db) {
        [db closeOpenResultSets];
        
        // all the database version should begins from 1 (DO NOT begins from 0 !!!)
        NSInteger newVersion = [migrationProcessor currentVersion];
        if (!_dbFileExisted) { // create database directly
            if ([migrationProcessor setupDatabase:db]) {
                if (![self updateDatabaseVersion:newVersion handler:db]) {
                    NSAssert(NO, @"update database veriosn failed!!!");
                    ret = NO;
                }
            } else {
                NSAssert(NO, @"Can not setup database: %@", _database.path);
                ret = NO;
            }
            return;
        }

        NSInteger dbVersion = [db intForQuery:@"PRAGMA user_version;"];
        NSAssert(dbVersion <= newVersion, @"Illegal database version. original:%@, new version:%@", @(dbVersion),
                 @(newVersion));
        
        if (dbVersion < newVersion) {
            if ([migrationProcessor migrateFromVersion:dbVersion to:newVersion databaseHandler:db]) {
                if (![self updateDatabaseVersion:newVersion handler:db]) {
                    NSAssert(NO, @"update database veriosn failed!!!");
                    ret = NO;
                }
            } else {
                NSAssert(NO, @"migrate from version %@ to %@ failed!!! database: %@", @(dbVersion), @(newVersion),
                         _database.path);
                ret = NO;
            }
        }
    }];
    
    return ret;
}

- (BOOL)updateDatabaseVersion:(NSInteger)version handler:(FMDatabase *)db {
    BOOL ret = [db executeUpdate:@"PRAGMA user_version=?;", @(version)];
    if (!ret) {
        ALLogWarn(@"*** update database version to %@ failed\npath: %@\nerror:%@", @(version), _database.path,
                  [db lastError]);
    }
    return ret;
}

- (void)close {
    [kDatabaseDict removeObjectForKey:_database.path];
    [_database close];
}



- (NSSet<Class> *)tableModels {
    if (_tableModels != nil) {
        return _tableModels;
    }

    _tableModels =
        [[ALOCRuntime classConfirmsToProtocol:@protocol(ALDatabaseModelProtocol)] bk_select:^BOOL(Class cls) {
            return [cls respondsToSelector:@selector(databasePath)] &&
                   [[cls databasePath] isEqualToString:_database.path];
        }];

    return _tableModels;
}

#pragma mark - database operations

- (ALSQLSelectBlock)SELECT {
    return ^ ALSQLSelectCommand *_Nonnull (NSArray<NSString *> *_Nullable columns) {
        ALSQLSelectCommand *command = [ALSQLSelectCommand commandWithDatabase:nil];
        command.SELECT(columns);
        return command;
    };
}

- (ALSQLUpdateBlock)UPDATE {
    return ^ALSQLUpdateCommand *_Nonnull(NSString *_Nonnull table) {
        ALSQLUpdateCommand *command = [ALSQLUpdateCommand commandWithDatabase:nil];
        command.UPDATE(table);
        return command;
    };
}

- (ALSQLInsertBlock)INSERT {
    return ^ALSQLInsertCommand *_Nonnull(NSString *_Nonnull table) {
        ALSQLInsertCommand *command = [ALSQLInsertCommand commandWithDatabase:nil];
        command.INSERT(table);
        return command;
    };
}

@end

NS_ASSUME_NONNULL_END
