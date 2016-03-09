//
//  ALSQLInsertCommand.h
//  patchwork
//
//  Created by Alex Lee on 2/23/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALSQLCommand.h"


NS_ASSUME_NONNULL_BEGIN

@class  ALSQLInsertCommand;
@class  ALSQLSelectCommand;
typedef ALSQLInsertCommand *_Nonnull (^ALSQLInsertBlockString)    (NSString                     *_Nonnull str);
typedef ALSQLInsertCommand *_Nonnull (^ALSQLInsertBlockDict)      (NSDictionary<NSString *, id> *_Nonnull values);
typedef ALSQLInsertCommand *_Nonnull (^ALSQLInsertBlockStrArray)  (NSArray<NSString *>          *_Nonnull strs);

typedef ALSQLInsertCommand *_Nonnull (^ALSQLInsertBlockSubSelect) (ALSQLSelectCommand           *_Nonnull command);

@interface ALSQLInsertCommand : ALSQLCommand

@property(readonly) ALSQLInsertBlockString    INSERT;
@property(readonly) ALSQLInsertBlockString    POLICY;
@property(readonly) ALSQLInsertBlockDict      VALUES;

@property(readonly) ALSQLInsertBlockSubSelect SELECT;

@end

NS_ASSUME_NONNULL_END
