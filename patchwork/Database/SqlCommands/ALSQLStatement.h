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
- (ALSQLClause *_Nullable)SQLClause;

@end


@interface ALSQLStatement (SQLExecute)
@property(readonly, copy) void (^EXECUTE_QUERY) (void (^_Nullable)(FMResultSet *_Nullable rs));
@property(readonly, copy) BOOL (^EXECUTE_UPDATE)();

- (void)executeWithCompletion:(void (^)(BOOL result))completion;

- (BOOL)validateWitherror:(NSError*_Nullable *)error;
@end


@interface ALSQLStatement (ALDebug)
@property(readonly, copy, nullable) NSString *argumentsDescription;
@end

NS_ASSUME_NONNULL_END
