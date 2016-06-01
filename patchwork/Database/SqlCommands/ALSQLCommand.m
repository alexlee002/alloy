//
//  ALSQLCommand.m
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALSQLCommand.h"
#import "ALDatabase.h"


NS_ASSUME_NONNULL_BEGIN

NSString * const kALDBConflictPolicyRollback    = @"OR ROLLBACK";
NSString * const kALDBConflictPolicyAbort       = @"OR ABORT";
NSString * const kALDBConflictPolicyFail        = @"OR FAIL";
NSString * const kALDBConflictPolicyIgnore      = @"OR IGNORE";
NSString * const kALDBConflictPolicyReplace     = @"OR REPLACE";

@implementation ALSQLCommand

@synthesize db = _db;


+ (instancetype)commandWithDatabase:(ALDatabase *)db {
    ALSQLCommand *command = [[self alloc] init];
    command->_db = db;
    return command;
}

- (nullable NSString *)sql {
    return nil;
}

- (nullable NSArray  *)sqlArgs {
    return [_sqlArgs copy];
}

- (ALSQLExecuteQueryBlock)EXECUTE_QUERY {
    return ^(void (^resultHandler)(FMResultSet *_Nullable rs)) {
        [_db.queue inDatabase:^(FMDatabase * _Nonnull db) {
            NSString *sql = [self sql];
            ALLogVerbose(@"sql: %@\nargs: %@", sql, _sqlArgs);
            FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:_sqlArgs];
            if (resultHandler) {
                resultHandler(rs);
            }
            [rs close];
        }];
    };
}

- (ALSQLExecuteUpdateBlock)EXECUTE_UPDATE {
    return ^BOOL(void) {
        __block BOOL rs = YES;
        [_db.queue inDatabase:^(FMDatabase * _Nonnull db) {
            NSString *sql = [self sql];
            ALLogVerbose(@"sql: %@\nargs: %@", sql, _sqlArgs);
            rs = [db executeUpdate:sql withArgumentsInArray:_sqlArgs];
        }];
        return rs;
    };
}


@end

NS_ASSUME_NONNULL_END
