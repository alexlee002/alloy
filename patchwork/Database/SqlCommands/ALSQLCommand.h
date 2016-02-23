//
//  ALSQLCommand.h
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALSQLCondition.h"
#import "FMResultSet.h"

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


@class FMDatabase;
@interface ALSQLCommand : NSObject {
    @protected
    ALSQLCondition *_where;
    NSString       *_limit;
    NSArray        *_sqlArgs;
}

@property(nonatomic, readonly, weak) FMDatabase *db;

@property(nonatomic, readonly) ALSQLExecuteQueryBlock  EXECUTE_QUERY;
@property(nonatomic, readonly) ALSQLExecuteUpdateBlock EXECUTE_UPDATE;

+ (instancetype)commandWithDatabase:(FMDatabase *)db;

- (nullable NSString *)sql;
- (nullable NSArray  *)sqlArgs;

#pragma mark - execute raw sql
- (nullable FMResultSet *)executeQuery:(NSString *)sql, ...;
- (nullable FMResultSet *)executeQuery:(NSString *)sql arguments:(nullable NSArray *)args;
- (BOOL)executeUpdate:(NSString *)sql, ...;
- (BOOL)executeUpdate:(NSString *)sql arguments:(nullable NSArray *)args;

@end

NS_ASSUME_NONNULL_END
