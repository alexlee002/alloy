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
typedef ALSQLSelectCommand *_Nonnull (^ALSQLSelectBlockStrArray)  (NSArray<NSString *> *_Nullable strs);
typedef ALSQLSelectCommand *_Nonnull (^ALSQLSelectBlockString)    (NSString            *_Nullable str);
typedef ALSQLSelectCommand *_Nonnull (^ALSQLSelectConditionBlock) (ALSQLCondition      *_Nullable condition);
typedef ALSQLSelectCommand *_Nonnull (^ALSQLSelectBlockNumArray)  (NSArray<NSNumber *> *_Nullable nums);

// you can execute raw sql here, but not recommanded;
typedef ALSQLSelectCommand *_Nonnull (^ALSQLSelectRawWhereBLock)  (NSString *_Nullable str, NSArray *_Nullable args);

@interface ALSQLSelectCommand : ALSQLCommand

@property(readonly, nullable) NSArray<NSString *> *columns;

@property(readonly) ALSQLSelectBlockString    FROM;
@property(readonly) ALSQLSelectBlockStrArray  SELECT;
@property(readonly) ALSQLSelectConditionBlock WHERE;
@property(readonly) ALSQLSelectBlockStrArray  ORDER_BY;
@property(readonly) ALSQLSelectBlockStrArray  GROUP_BY;
@property(readonly) ALSQLSelectBlockNumArray  LIMIT;

@property(readonly) ALSQLSelectRawWhereBLock  RAW_WHERE;

@end

NS_ASSUME_NONNULL_END
