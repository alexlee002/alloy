//
//  ALSQLDeleteCommand.h
//  patchwork
//
//  Created by Alex Lee on 2/23/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALSQLCommand.h"

NS_ASSUME_NONNULL_BEGIN

@class  ALSQLDeleteCommand;
@class  ALSQLCondition;
typedef ALSQLDeleteCommand *_Nonnull (^ALSQLDeleteBlockString)    (NSString            *_Nullable str);
typedef ALSQLDeleteCommand *_Nonnull (^ALSQLDeleteConditionBlock) (ALSQLCondition      *_Nullable condition);

@interface ALSQLDeleteCommand : ALSQLCommand

@property(readonly) ALSQLDeleteBlockString       DELETE_FROM;
//@property(readonly) ALSQLDeleteBlockString       TRUNCATE;
@property(readonly) ALSQLDeleteConditionBlock    WHERE;

@end

NS_ASSUME_NONNULL_END
