//
//  ALFMDatabaseQueue.m
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALFMDatabaseQueue.h"
#import "FMDB.h"
#import "UtilitiesHeader.h"
#import "ALOCRuntime.h"
#import "PatchworkLog_private.h"
#import <sqlite3.h>

#ifndef MAX_DB_BLOCK_EXECUTE_SEC
#define MAX_DB_BLOCK_EXECUTE_SEC 5
#endif

#ifndef MAX_DB_BLOCK_EXECUTE_SEC_MAIN
#define MAX_DB_BLOCK_EXECUTE_SEC_MAIN 0.5f
#endif

#if defined(DEBUG) && DEBUG
    #define OP_BLOCK(block) ({                              \
            CFTimeInterval t = CFAbsoluteTimeGetCurrent();  \
            block();                                        \
            t = CFAbsoluteTimeGetCurrent() - t;             \
            CFTimeInterval timeLimit = [NSThread mainThread] ? MAX_DB_BLOCK_EXECUTE_SEC_MAIN : MAX_DB_BLOCK_EXECUTE_SEC; \
            if (t > timeLimit) {             \
                ALLogWarn(@"!!!Database operation time exceeded! Expected:%.2fs, was: %.2fs.\nBacktrace Stack:\n%@", timeLimit, t, backtraceStack(15));\
            }                                               \
        })
#else
    #define OP_BLOCK(block) block()
#endif


NS_ASSUME_NONNULL_BEGIN

static const void * const kDispatchQueueSpecificKey = &kDispatchQueueSpecificKey;

@implementation ALFMDatabaseQueue {
    dispatch_queue_t  _queue;
    FMDatabase       *_db;
    int               _openFlags;
}

- (nullable instancetype)initWithPath:(nullable NSString*)aPath {
    return [self initWithPath:aPath flags:SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE vfs:nil];
}

- (nullable instancetype)initWithPath:(nullable NSString*)aPath flags:(int)openFlags {
    return [self initWithPath:aPath flags:openFlags vfs:nil];
}

- (instancetype)initWithPath:(nullable NSString*)aPath flags:(int)openFlags vfs:(nullable NSString *)vfsName {
    
    self = [super init];
    
    if (self != nil) {
        
        _db = [[[self class] databaseClass] databaseWithPath:aPath];
        FMDBRetain(_db);
        
#if SQLITE_VERSION_NUMBER >= 3005000
        BOOL success = [_db openWithFlags:openFlags vfs:vfsName];
#else
        BOOL success = [_db open];
#endif
        if (!success) {
            NSLog(@"Could not create database queue for path %@", aPath);
            FMDBRelease(self);
            return 0x00;
        }
        
        _path = FMDBReturnRetained(aPath);
        
        _queue = dispatch_queue_create([[NSString stringWithFormat:@"fmdb.%@", self] UTF8String], NULL);
        dispatch_queue_set_specific(_queue, kDispatchQueueSpecificKey, (__bridge void *)self, NULL);
        _openFlags = openFlags;
    }
    
    return self;
}

+ (Class)databaseClass {
    return [FMDatabase class];
}

- (void)dealloc {
    
    FMDBRelease(_db);
    FMDBRelease(_path);
    
    if (_queue) {
        FMDBDispatchQueueRelease(_queue);
        _queue = 0x00;
    }
#if ! __has_feature(objc_arc)
    [super dealloc];
#endif
}

- (void)close {
    FMDBRetain(self);
    dispatch_sync(_queue, ^() {
        [self->_db close];
        FMDBRelease(_db);
        self->_db = 0x00;
    });
    FMDBRelease(self);
}

- (nullable FMDatabase*)database {
    if (!_db) {
        _db = FMDBReturnRetained([FMDatabase databaseWithPath:_path]);
        
#if SQLITE_VERSION_NUMBER >= 3005000
        BOOL success = [_db openWithFlags:_openFlags];
#else
        BOOL success = [_db open];
#endif
        if (!success) {
            ALLogError(@"ALFMDatabaseQueue could not reopen database for path %@", _path);
            FMDBRelease(_db);
            _db  = 0x00;
            return 0x00;
        }
    }
    
    return _db;
}


- (void)safelyRun:(void (^)(void))block {
    ALFMDatabaseQueue *currentSyncQueue = (__bridge id)dispatch_get_specific(kDispatchQueueSpecificKey);
    if (currentSyncQueue == self) {
        _ALDBLog(@"!!! Nested database operation blocks!");
        OP_BLOCK(block);
    } else {
        dispatch_sync(_queue, ^{
            OP_BLOCK(block);
        });
    }
}


- (void)inDatabase:(void (^)(FMDatabase *db))block {
    FMDBRetain(self);
    
    [self safelyRun:^{
        FMDatabase *db = [self database];
        block(db);
        
        if ([db hasOpenResultSets]) {
            ALLogWarn(@"!!! there is at least one open result set around after performing [ALFMDatabaseQueue inDatabase:]");
            
#if defined(DEBUG) && DEBUG
            NSSet *openSetCopy = FMDBReturnAutoreleased([[db valueForKey:@"_openResultSets"] copy]);
            for (NSValue *rsInWrappedInATastyValueMeal in openSetCopy) {
                FMResultSet *rs = (FMResultSet *)[rsInWrappedInATastyValueMeal pointerValue];
                ALLogWarn(@"unexpected opening result set query: '%@'", [rs query]);
            }
#endif
        }
    }];
    
    FMDBRelease(self);
}

- (void)beginTransaction:(BOOL)useDeferred withBlock:(void (^)(FMDatabase *db, BOOL *rollback))block {
    FMDBRetain(self);
    [self safelyRun:^{
        BOOL shouldRollback = NO;
        BOOL isIntransaction = [[self database] inTransaction];
#if defined(DEBUG) && DEBUG
        if (isIntransaction) {
            ALLogWarn(@"!!! Nested database transation.");
        }
#endif
        if (!isIntransaction) {
            if (useDeferred) {
                [[self database] beginDeferredTransaction];
            }
            else {
                [[self database] beginTransaction];
            }
        }
        
        block([self database], &shouldRollback);
        
        if (!isIntransaction) {
            if (shouldRollback) {
                [[self database] rollback];
            }
            else {
                [[self database] commit];
            }
        }
    }];
    
    FMDBRelease(self);
}

- (void)inDeferredTransaction:(void (^)(FMDatabase *db, BOOL *rollback))block {
    [self beginTransaction:YES withBlock:block];
}

- (void)inTransaction:(void (^)(FMDatabase *db, BOOL *rollback))block {
    [self beginTransaction:NO withBlock:block];
}

@end

#if SQLITE_VERSION_NUMBER >= 3007000
#define __verify_savepoint_support(returnBool) do {} while (0)
#else
#define __verify_savepoint_support(returnBool)                                                   \
    NSString *errorMessage = NSLocalizedString(@"Save point functions require SQLite 3.7", nil); \
    if (self.logsErrors) _ALDBLogE(@"Error: %@", errorMessage);                                  \
    return returnBool                                                                            \
               ? NO                                                                              \
               : [NSError errorWithDomain:@"FMDatabase" code:0 userInfo:@{NSLocalizedDescriptionKey : errorMessage}];
#endif

@implementation ALFMDatabaseQueue (SavePoint)

- (BOOL)startSavePointNamed:(NSString *)name error:(NSError*_Nullable *)outErr {
    __verify_savepoint_support(YES);
    
    FMDBRetain(self);
    __block BOOL result = YES;
    [self safelyRun:^{
        result = [[self database] startSavePointWithName:name error:outErr];
    }];
    FMDBRelease(self);
    return result;
}

- (BOOL)releaseSavePointNamed:(NSString*)name error:(NSError*_Nullable*)outErr {
    __verify_savepoint_support(YES);
    
    FMDBRetain(self);
    __block BOOL result = YES;
    [self safelyRun:^{
        result = [[self database] releaseSavePointWithName:name error:outErr];
    }];
    FMDBRelease(self);
    return result;
}

- (BOOL)rollbackToSavePointNamed:(NSString*)name error:(NSError*_Nullable*)outErr {
    __verify_savepoint_support(YES);
    
    FMDBRetain(self);
    __block BOOL result = YES;
    [self safelyRun:^{
        result = [[self database] rollbackToSavePointWithName:name error:outErr];
    }];
    FMDBRelease(self);
    return result;
}

- (nullable NSError *)inSavePoint:(void (^)(FMDatabase *db, BOOL *rollback))block {
    __verify_savepoint_support(NO);
    
    static unsigned long savePointIdx = 0;
    __block NSError *err = 0x00;
    FMDBRetain(self);
    [self safelyRun:^ {
        
        NSString *name = [NSString stringWithFormat:@"savePoint_%ld", savePointIdx++];
        
        BOOL shouldRollback = NO;
        
        if ([[self database] startSavePointWithName:name error:&err]) {
            
            block([self database], &shouldRollback);
            
            if (shouldRollback) {
                // We need to rollback and release this savepoint to remove it
                [[self database] rollbackToSavePointWithName:name error:&err];
            }
            [[self database] releaseSavePointWithName:name error:&err];
        }
    }];
    FMDBRelease(self);
    return err;
}

@end

@implementation ALFMDatabaseQueue (ALExtension)

- (void)setShouldCacheStatements:(BOOL)shouldCacheStatements {
    [self database].shouldCacheStatements = shouldCacheStatements;
}

- (BOOL)shouldCacheStatements {
    return [self database].shouldCacheStatements;
}

@end

NS_ASSUME_NONNULL_END
