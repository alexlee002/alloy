//
//  ALSQLUpdateCommand.h
//  patchwork
//
//  Created by Alex Lee on 2/22/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALSQLCommand.h"


NS_ASSUME_NONNULL_BEGIN

@class  ALSQLUpdateCommand;
typedef ALSQLUpdateCommand *_Nonnull (^ALSQLUpdateBlockString)    (NSString            *_Nullable str);
typedef ALSQLUpdateCommand *_Nonnull (^ALSQLUpdateConditionBlock) (ALSQLCondition      *_Nonnull  condition);
typedef ALSQLUpdateCommand *_Nonnull (^ALSQLUpdateBlockDict)      (NSDictionary<NSString *, id> *_Nonnull values);
typedef ALSQLUpdateCommand *_Nonnull (^ALSQLUpdateBlockStrId)     (NSString *_Nullable str, id obj);

@interface ALSQLUpdateCommand : ALSQLCommand

@property(readonly) ALSQLUpdateBlockString    UPDATE;
@property(readonly) ALSQLUpdateBlockString    POLICY;
@property(readonly) ALSQLUpdateBlockDict      VALUES;  //set multi values
@property(readonly) ALSQLUpdateBlockStrId     SET;     //set one value
@property(readonly) ALSQLUpdateConditionBlock WHERE;

@end

NS_ASSUME_NONNULL_END
