//
//  ALSQLCommand.m
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALSQLCommand.h"
#import "FMDatabase.h"


NS_ASSUME_NONNULL_BEGIN

NSString * const kALDBConflictPolicyRollback    = @"OR ROLLBACK";
NSString * const kALDBConflictPolicyAbort       = @"OR ABORT";
NSString * const kALDBConflictPolicyFail        = @"OR FAIL";
NSString * const kALDBConflictPolicyIgnore      = @"OR IGNORE";
NSString * const kALDBConflictPolicyReplace     = @"OR REPLACE";

@implementation ALSQLCommand

@synthesize db = _db;


+ (instancetype)commandWithDatabase:(FMDatabase *)db {
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
    return ^FMResultSet *_Nullable(void) {
        return [_db executeQuery:[self sql] withArgumentsInArray:_sqlArgs];
    };
}

- (ALSQLExecuteUpdateBlock)EXECUTE_UPDATE {
    return ^BOOL(void) {
        return [_db executeUpdate:[self sql] withArgumentsInArray:_sqlArgs];
    };
}


@end

NS_ASSUME_NONNULL_END
