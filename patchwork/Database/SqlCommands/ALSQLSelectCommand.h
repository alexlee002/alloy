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

@interface ALSQLSelectCommand : ALSQLCommand

@property(nonatomic, readonly, nullable) NSArray<NSString *> *columns;

@property(nonatomic, readonly) ALSQLSelectBlockString    FROM;
@property(nonatomic, readonly) ALSQLSelectBlockStrArray  SELECT;
@property(nonatomic, readonly) ALSQLSelectConditionBlock WHERE;
@property(nonatomic, readonly) ALSQLSelectBlockStrArray  ORDER_BY;
@property(nonatomic, readonly) ALSQLSelectBlockStrArray  GROUP_BY;
@property(nonatomic, readonly) ALSQLSelectBlockNumArray  LIMIT;

@end

NS_ASSUME_NONNULL_END
