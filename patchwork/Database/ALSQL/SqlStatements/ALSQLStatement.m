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
#import "__patchwork_config.h"

#define __STMT_EXEC_LOG(result, db)                                                                                   \
    {                                                                                                                 \
        if ((result)) {                                                                                               \
            _ALDBLog(@"Execute SQL: %@; ✔", self.db.enableDebug ? [self debugDescription] : [self description]);      \
        } else {                                                                                                      \
            ALAssert(NO, @"DB ERROR: %@; \nSQL: %@; \narguments:%@", [db lastError], self.SQLString, self.argValues); \
        }                                                                                                             \
    }

NS_ASSUME_NONNULL_BEGIN

@interface ALSQLStatement (AL_NSObject_Ext)
@end
@implementation ALSQLStatement(AL_NSObject_Ext)

- (nullable ALSQLClause *)al_SQLClause {
    return [self SQLClause];
}

@end


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
    al_weakify(self);
    return ^(void (^resultHaldler)(FMResultSet *_Nullable rs)) {
        al_strongify(self);
        
        if (!al_objIsValidBlocksChainObject(self)) {
            ALSafeInvokeBlock(resultHaldler, nil);
            return;
        }
        
        if (self.db == nil) {
            ALLogWarn(@"*** Invalid database handler");
            ALSafeInvokeBlock(resultHaldler, nil);
            return;
        }
        
        [self.db.queue inDatabase:^(FMDatabase * _Nonnull db) {
            FMResultSet *rs = [db executeQuery:self.SQLString withArgumentsInArray:self.argValues];
            __STMT_EXEC_LOG(rs != nil, db);
            ALSafeInvokeBlock(resultHaldler, rs);
            [rs close];
        }];
    };
}

- (BOOL (^)())EXECUTE_UPDATE {
    al_weakify(self);
    return ^BOOL () {
        al_strongify(self);
        
        if (!al_objIsValidBlocksChainObject(self)) {
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
    if (!al_objIsValidBlocksChainObject(self)) {
        ALSafeInvokeBlock(completion, NO);
        return;
    }
    
    if (self.db == nil) {
        ALLogWarn(@"*** Invalid database handler");
        ALSafeInvokeBlock(completion, NO);
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

- (NSString *)description {
    return [[self.SQLString al_SQLClauseWithArgValues:self.argValues] description];
}

- (NSString *)debugDescription {
    return [[self.SQLString al_SQLClauseWithArgValues:self.argValues] debugDescription];
}

@end

NS_ASSUME_NONNULL_END
