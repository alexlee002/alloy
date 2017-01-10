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

extern NSString * const kALInMemoryDBPath;  // in-memory db
extern NSString * const kALTempDBPath;      // temp db;

@interface ALDatabase : NSObject

@property(readonly) ALFMDatabaseQueue *queue;
@property(readonly, getter=isReadonly) BOOL               readonly; // Is databas opened in readonly mode?

// The following methods open a database with specified path,
// @see: http://www.sqlite.org/c3ref/open.html

// database opened in default mode.
+ (nullable instancetype)databaseWithPath:(NSString *)path;

// database opened in readonly mode. -- experimental
+ (nullable instancetype)readonlyDatabaseWithPath:(NSString *)path;

// database opened in readonly mode, and bind to caller's thread local -- experimental
+ (nullable instancetype)threadLocalReadonlyDatabaseWithPath:(NSString *)path;

- (void)close;

@end

@interface ALDatabase (ALDebug)
@property(nonatomic) BOOL enableDebug;
@end


@interface ALDatabase (ALSQLStatment)

@property(readonly, copy) ALSQLSelectStatement *(^SELECT)  (id _Nullable resultColumns);
@property(readonly, copy) ALSQLInsertStatement *(^INSERT)  ();
@property(readonly, copy) ALSQLInsertStatement *(^REPLACE) ();
@property(readonly, copy) ALSQLDeleteStatement *(^DELETE)  ();
@property(readonly, copy) ALSQLUpdateStatement *(^UPDATE)  (id qualifiedTableName);

@end

NS_ASSUME_NONNULL_END
