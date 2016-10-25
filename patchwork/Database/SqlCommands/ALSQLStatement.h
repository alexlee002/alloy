//
//  ALSQLStatement.h
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDB.h"
//#import "ALDatabase.h"
#import "ALSQLClause.h"

NS_ASSUME_NONNULL_BEGIN

@class ALDatabase;
@interface ALSQLStatement : NSObject

@property(readonly, weak) ALDatabase *db;
@property(readonly, copy, nullable) NSString *SQLString;
@property(readonly, copy, nullable) NSArray  *argValues;

+ (instancetype)statementWithDatabase:(ALDatabase *)db;

- (ALSQLClause *_Nullable)toSQL;
@end


//@interface ALSQLCommand (BlocksChain)
//
//@property(readonly, copy) ALSQLCommand *(^WHERE) (ALSQLClause *clause);
//@property(readonly, copy) ALSQLCommand *(^OFFSET)(NSInteger offset);
//@property(readonly, copy)
//
//@end


//#pragma mark - typedefs
//
//typedef void (^ALSQLExecuteQueryBlock)  (void (^)(FMResultSet *_Nullable rs));
//typedef BOOL (^ALSQLExecuteUpdateBlock) (void);
//
//#pragma mark - constants
//extern NSString * const kALDBConflictPolicyRollback;
//extern NSString * const kALDBConflictPolicyAbort;
//extern NSString * const kALDBConflictPolicyFail;
//extern NSString * const kALDBConflictPolicyIgnore;
//extern NSString * const kALDBConflictPolicyReplace;
//
//#pragma mark - functions
//
//
//@class ALDatabase;
//@interface ALSQLCommand : NSObject {
//    @protected
//    ALSQLCondition *_where;
//    NSNumber       *_limit;
//    NSNumber       *_offset;
//    NSArray        *_sqlArgs;
//}
//
//@property(readonly, weak) ALDatabase *db;
//
//@property(readonly) ALSQLExecuteQueryBlock  EXECUTE_QUERY;
//@property(readonly) ALSQLExecuteUpdateBlock EXECUTE_UPDATE;
//
//+ (instancetype)commandWithDatabase:(ALDatabase *)db;
//
//- (nullable NSString *)sql;
//- (nullable NSArray  *)sqlArgs;
//
//@end

NS_ASSUME_NONNULL_END
