//
//  ALSQLCommand.h
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALSQLCondition.h"
#import "FMDB.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - typedefs

typedef FMResultSet *_Nullable (^ALSQLExecuteQueryBlock)  (void);
typedef BOOL                   (^ALSQLExecuteUpdateBlock) (void);

#pragma mark - constants
extern NSString * const kALDBConflictPolicyRollback;
extern NSString * const kALDBConflictPolicyAbort;
extern NSString * const kALDBConflictPolicyFail;
extern NSString * const kALDBConflictPolicyIgnore;
extern NSString * const kALDBConflictPolicyReplace;

#pragma mark - functions


@class ALDatabase;
@interface ALSQLCommand : NSObject {
    @protected
    ALSQLCondition *_where;
    NSString       *_limit;
    NSArray        *_sqlArgs;
}

@property(nonatomic, readonly, weak) ALDatabase *db;

@property(nonatomic, readonly) ALSQLExecuteQueryBlock  EXECUTE_QUERY;
@property(nonatomic, readonly) ALSQLExecuteUpdateBlock EXECUTE_UPDATE;

+ (instancetype)commandWithDatabase:(ALDatabase *)db;

- (nullable NSString *)sql;
- (nullable NSArray  *)sqlArgs;

@end

NS_ASSUME_NONNULL_END