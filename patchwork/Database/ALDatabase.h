//
//  ALDatabase.h
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALFMDatabaseQueue.h"
#import "ALSQLDeleteStatement.h"
#import "ALSQLInsertStatement.h"
#import "ALSQLSelectStatement.h"
#import "ALSQLUpdateStatement.h"

NS_ASSUME_NONNULL_BEGIN

//typedef ALDatabase *_Nonnull (^ALDatabaseBlockStrArray)(NSArray<NSString *> *_Nullable strs);
typedef ALSQLSelectStatement *_Nonnull (^ALSQLSelectBlock)(NSArray<NSString *> *_Nullable columns);
typedef ALSQLUpdateStatement *_Nonnull (^ALSQLUpdateBlock)(NSString *_Nonnull table);
typedef ALSQLInsertStatement *_Nonnull (^ALSQLInsertBlock)(NSString *_Nonnull table);
typedef ALSQLDeleteStatement *_Nonnull (^ALSQLDeleteBlock)(NSString *_Nonnull table);


@interface ALDatabase : NSObject

@property(readonly) ALFMDatabaseQueue *queue;

@property(readonly) ALSQLSelectBlock     SELECT;
@property(readonly) ALSQLUpdateBlock     UPDATE;
@property(readonly) ALSQLInsertBlock     INSERT;
@property(readonly) ALSQLDeleteBlock     DELETE_FROM;

+ (nullable instancetype)databaseWithPath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
