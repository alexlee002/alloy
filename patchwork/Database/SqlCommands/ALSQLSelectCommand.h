//
//  ALSQLSelectCommand.h
//  patchwork
//
//  Created by Alex Lee on 2/22/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALSQLCommand.h"

NS_ASSUME_NONNULL_BEGIN

@class  ALSQLSelectCommand;
typedef ALSQLSelectCommand *_Nonnull (^ALSQLSelectBlockArray)     (NSArray             *_Nullable strs);
typedef ALSQLSelectCommand *_Nonnull (^ALSQLSelectBlockString)    (NSString            *_Nullable str);
typedef ALSQLSelectCommand *_Nonnull (^ALSQLSelectConditionBlock) (ALSQLCondition      *_Nullable condition);
typedef ALSQLSelectCommand *_Nonnull (^ALSQLSelectBlockInt)       (NSInteger                      num);
typedef ALSQLSelectCommand *_Nonnull (^ALSQLSelectBlockId)        (id                   _Nullable value);

// you can execute raw sql here, but not recommanded;
typedef ALSQLSelectCommand *_Nonnull (^ALSQLSelectRawWhereBLock)  (NSString *_Nullable str, NSArray *_Nullable args);

@interface ALSQLSelectCommand : ALSQLCommand

@property(readonly, nullable) NSArray<NSString *> *columns;

@property(readonly) ALSQLSelectBlockId        FROM;
@property(readonly) ALSQLSelectBlockArray     SELECT;
@property(readonly) ALSQLSelectConditionBlock WHERE;
/**
 *  eg: ORDER_BYS[ @[@"col1", @"col2 DESC", @"col3"] ]
 */
@property(readonly) ALSQLSelectBlockArray     ORDER_BYS;
@property(readonly) ALSQLSelectBlockArray     GROUP_BYS;
/**
 *  eg: ORDER_BY(@"col1").ORDER_BY(@"col2 DESC").ORDER_BY(@"col3")
 */
@property(readonly) ALSQLSelectBlockId        ORDER_BY;
@property(readonly) ALSQLSelectBlockId        GROUP_BY;
@property(readonly) ALSQLSelectBlockInt       LIMIT;
@property(readonly) ALSQLSelectBlockInt       OFFSET;

@property(readonly) ALSQLSelectRawWhereBLock  RAW_WHERE;

@end

NS_ASSUME_NONNULL_END
