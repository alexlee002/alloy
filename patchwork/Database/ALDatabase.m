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

#import <objc/runtime.h>

//// undefine blockskit's macro define, conflict with property: SELECT
//#undef SELECT


NS_ASSUME_NONNULL_BEGIN

static NSString *const kVersionTable                = @"tbl_versions";
static NSString *const kVersionTableColumnTableName = @"table_name";
static NSString *const kVersionTableColumnVersion   = @"version";

static NSMutableDictionary<NSString *, ALDatabase *>   *kDatabaseDict = nil;

@implementation ALDatabase {
    //ALFMDatabaseQueue *_database;
    NSSet<Class>      *_tableModels;
    
    //__kindof ALSQLCommand  *_sqlCommand;
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
        if((db = [[self alloc] initWithPath:path]) != nil && [db open]) {
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
        _database = [[ALFMDatabaseQueue alloc] initWithPath:path];
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
    
    __block BOOL ret = YES;
    [_database inDatabase:^(FMDatabase * _Nonnull db) {
        [self setupVersionTable:db];
        
        NSMutableSet *existedTables = [[self existedTables:db] mutableCopy];
        NSMutableDictionary *dbVerDict = [[self dbTableVersions:db] mutableCopy];
        
        [objTables enumerateObjectsUsingBlock:^(Class  _Nonnull cls, BOOL * _Nonnull stop) {
            NSString *tblName = [cls tableName];
            NSNumber *tblVer = dbVerDict[tblName];
            if (![existedTables containsObject:tblName]) { // table not found
                if ([cls createTable:db]) {
                    [self updateTableVersionForModel:cls database:db];
                }
            } else if (tblVer == nil) { // lost version info
                ALLogError(@"lost version information for table: %@", tblName);
                //TODO: try auto migrations
                ret = NO;
            } else {
                NSUInteger oldVer = tblVer.unsignedIntegerValue;
                NSUInteger newVer = [cls tableVersion];
                if (oldVer < newVer) {
                    if ([cls upgradeTableFromVersion:oldVer toVerion:newVer database:db]) {
                        [self updateTableVersionForModel:cls database:db];
                    }
                } else if (oldVer > newVer) {
                    ALLogError(@"incorrect version information for table: %@", tblName);
                    ret = NO;
                }
            }
            
            [existedTables removeObject:tblName];
            [dbVerDict removeObjectForKey:tblName];
        }];
        
        // remove useless table version informations
        [dbVerDict bk_each:^(NSString *name, id obj) {
            [self removeTableVersionForTable:name database:db];
        }];
        
        //TODO: how to process the existed-tables but without any matched model?
    }];
    
    return ret;
}

- (void)close {
    [kDatabaseDict removeObjectForKey:_database.path];
    [_database close];
}

#pragma mark version table
- (BOOL)setupVersionTable:(FMDatabase *)db {
    NSString *sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ ("
                     @"%@ TEXT UNIQUE, "
                     @"%@ INTEGER)",
                     kVersionTable, kVersionTableColumnTableName, kVersionTableColumnVersion];
    return [db executeUpdate:sql];
}

- (BOOL)updateTableVersionForModel:(Class)clazz database:(FMDatabase *)db {
    NSString *sql = [NSString stringWithFormat:@"INSERT OR REPLACE INTO %@ (%@, %@) VALUES (?, ?)", kVersionTable,
                                               kVersionTableColumnTableName, kVersionTableColumnVersion];
    return [db executeUpdate:sql, [clazz tableName], @([clazz tableVersion])];
}

- (BOOL)removeTableVersionForTable:(NSString *)tblName database:(FMDatabase *)db {
    return [db executeUpdate:[NSString stringWithFormat:@"DELETE FROM %@ WHERE %@=?", kVersionTable,
                                                        kVersionTableColumnTableName],
                             tblName];
}

- (nullable NSDictionary<NSString *, NSNumber *> *)dbTableVersions:(FMDatabase *)db {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    FMResultSet *rs = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM %@", kVersionTable]];
    while ([rs next]) {
        dict[ [rs stringForColumn:kVersionTableColumnTableName] ] = @([rs intForColumn:kVersionTableColumnVersion]);
    }
    [rs close];
    
    return dict.count > 0 ? dict : nil;
}

- (nullable NSSet<NSString *> *)existedTables:(FMDatabase *)db {
    NSMutableSet *set = [NSMutableSet set];
    FMResultSet *rs =
        [db executeQuery:@"SELECT tbl_name FROM sqlite_master WHERE type=? AND tbl_name!=? AND name NOT LIKE ?",
                         @"table", kVersionTable, @"sqlite_%"];
    while ([rs next]) {
        [set addObject:[rs stringForColumnIndex:0]];
    }
    [rs close];
    return set.count > 0 ? set : nil;
}

- (NSSet<Class> *)tableModels {
    if (_tableModels != nil) {
        return _tableModels;
    }
    
    NSMutableSet *set = [NSMutableSet set];
    unsigned int classesCount = 0;
    Class *classes = objc_copyClassList( &classesCount );
    for (int i = 0; i < classesCount; ++i) {
        Class clazz = classes[i];
        Class superClass = class_getSuperclass(clazz);

        if (nil == superClass) {
            continue;
        }
        if (!class_respondsToSelector(clazz, @selector(doesNotRecognizeSelector:))) {
            continue;
        }
        if (!class_respondsToSelector(clazz, @selector(methodSignatureForSelector:))) {
            continue;
        }

        if ([clazz conformsToProtocol:@protocol(ALDatabaseModelProtocol)] &&
            [clazz respondsToSelector:@selector(databasePath)]) {
            if ([[clazz databasePath] isEqualToString:_database.path]) {
                [set addObject:clazz];
            }
        }
    }
    free(classes);
    _tableModels = set;
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
