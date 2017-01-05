//
//  ALSQLStatement.m
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALSQLStatement.h"
#import "ALDatabase.h"
#import "SafeBlocksChain.h"
#import "PatchworkLog_private.h"

#define __STMT_EXEC_LOG(result, db)     {                                               \
    ALSQLClause *clause = [self.SQLString SQLClauseWithArgValues:self.argValues];       \
    if ((result)) {                                                                     \
        _ALDBLog(@"Execute SQL: %@; ✔", self.db.enableDebug ? [clause debugDescription] : [clause description]);   \
    } else {                                                                            \
        ALLogError(@"Execute SQL: %@; ✘ ERROR: %@", self.db.enableDebug ? [clause debugDescription] : [clause description], [db lastError]);     \
    }                                                                                   \
}

NS_ASSUME_NONNULL_BEGIN

@implementation ALSQLStatement

@synthesize db = _db;

+ (instancetype)statementWithDatabase:(ALDatabase *)db {
    ALSQLStatement *stmt = [[self alloc] init];
    stmt->_db = db;
    return stmt;
}

- (nullable ALSQLClause *)SQLClause {
    return nil;
}

- (nullable NSString *)SQLString {
    return [self SQLClause].SQLString;
}

- (nullable NSArray *)argValues {
    return [self SQLClause].argValues;
}

@end;

@implementation ALSQLStatement (SQLExecute)

- (void (^)(void (^)(FMResultSet *)))EXECUTE_QUERY {
    return ^(void (^resultHaldler)(FMResultSet *_Nullable rs)) {
        if (!ObjIsValidBlocksChainObject(self)) {
            safeInvokeBlock(resultHaldler, nil);
            return;
        }
        
        if (self.db == nil) {
            ALLogWarn(@"*** Invalid database handler");
            safeInvokeBlock(resultHaldler, nil);
            return;
        }
        
        [self.db.queue inDatabase:^(FMDatabase * _Nonnull db) {
            FMResultSet *rs = [db executeQuery:self.SQLString withArgumentsInArray:self.argValues];
            __STMT_EXEC_LOG(rs != nil, db);
            safeInvokeBlock(resultHaldler, rs);
            [rs close];
        }];
    };
}

- (BOOL (^)())EXECUTE_UPDATE {
    weakify(self);
    return ^BOOL () {
        strongify(self);
        if (!ObjIsValidBlocksChainObject(self)) {
            return NO;
        }
        
        if (self.db == nil) {
            ALLogWarn(@"*** Invalid database handler");
            return NO;
        }
        
        __block BOOL result = NO;
        [self.db.queue inDatabase:^(FMDatabase * _Nonnull db) {
            result = [db executeUpdate:self.SQLString withArgumentsInArray:self.argValues];
            __STMT_EXEC_LOG(result, db);
        }];
        
        return result;
    };
}

- (void)executeWithCompletion:(void (^)(BOOL))completion {
    if (!ObjIsValidBlocksChainObject(self)) {
        safeInvokeBlock(completion, NO);
        return;
    }
    
    if (self.db == nil) {
        ALLogWarn(@"*** Invalid database handler");
        safeInvokeBlock(completion, NO);
        return;
    }
    
    [self.db.queue inDatabase:^(FMDatabase * _Nonnull db) {
        BOOL result = [db executeUpdate:self.SQLString withArgumentsInArray:self.argValues];
        __STMT_EXEC_LOG(result, db);
    }];
}

- (BOOL)validateWitherror:(NSError**)error {
    __block BOOL result;
    __block NSError *innerError;
    [self.db.queue inDatabase:^(FMDatabase * _Nonnull db) {
        result = [db validateSQL:self.SQLString error:&innerError];
    }];
    if (error != nil) {
        *error = innerError;
    }
    return result;
}

@end


@implementation ALSQLStatement (ALDebug)

- (nullable NSString *)argumentsDescription {
    return self.argValues.description;
}

@end

NS_ASSUME_NONNULL_END
