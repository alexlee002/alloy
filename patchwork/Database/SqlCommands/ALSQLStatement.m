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
#import "ALLogger.h"

#define __STMT_EXEC_LOG(result)     {                                               \
    ALSQLClause *clause = [self.SQLString SQLClauseWithArgValues:self.argValues];   \
    ALLogVerbose(@"execute SQL: %@;  %@", self.db.enableDebug ? [clause debugDescription] : [clause description], \
                                          (result) ? @"✔" : @"🚫");                 \
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
        if (![self isValidBlocksChainObject]) {
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
            __STMT_EXEC_LOG(rs != nil);
            safeInvokeBlock(resultHaldler, rs);
            [rs close];
        }];
    };
}

- (BOOL (^)())EXECUTE_UPDATE {
    return ^BOOL () {
        if (![self isValidBlocksChainObject]) {
            return NO;
        }
        
        if (self.db == nil) {
            ALLogWarn(@"*** Invalid database handler");
            return NO;
        }
        
        __block BOOL result = NO;
        [self.db.queue inDatabase:^(FMDatabase * _Nonnull db) {
            result = [db executeUpdate:self.SQLString withArgumentsInArray:self.argValues];
            __STMT_EXEC_LOG(result);
        }];
        
        return result;
    };
}

- (void)executeWithCompletion:(void (^)(BOOL))completion {
    if (![self isValidBlocksChainObject]) {
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
        __STMT_EXEC_LOG(result);
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
