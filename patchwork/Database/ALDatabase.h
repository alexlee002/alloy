//
//  ALDatabase.h
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALFMDatabaseQueue.h"
#import "ALSQLDeleteCommand.h"
#import "ALSQLInsertCommand.h"
#import "ALSQLSelectCommand.h"
#import "ALSQLUpdateCommand.h"

NS_ASSUME_NONNULL_BEGIN

//typedef ALDatabase *_Nonnull (^ALDatabaseBlockStrArray)(NSArray<NSString *> *_Nullable strs);
typedef ALSQLSelectCommand *_Nonnull (^ALSQLSelectBlock)(NSArray<NSString *> *_Nullable columns);
typedef ALSQLUpdateCommand *_Nonnull (^ALSQLUpdateBlock)(NSString *_Nonnull table);
typedef ALSQLInsertCommand *_Nonnull (^ALSQLInsertBlock)(NSString *_Nonnull table);
typedef ALSQLDeleteCommand *_Nonnull (^ALSQLDeleteBlock)(NSString *_Nonnull table);


@interface ALDatabase : NSObject

@property(nonatomic, readonly) ALFMDatabaseQueue *queue;

@property(nonatomic, readonly) ALSQLSelectBlock     SELECT;
@property(nonatomic, readonly) ALSQLUpdateBlock     UPDATE;
@property(nonatomic, readonly) ALSQLInsertBlock     INSERT;
@property(nonatomic, readonly) ALSQLDeleteBlock     DELETE_FROM;

+ (nullable instancetype)databaseWithPath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
