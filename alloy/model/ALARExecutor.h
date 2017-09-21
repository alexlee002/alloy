//
//  ALARExecutor.h
//  alloy
//
//  Created by Alex Lee on 25/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALDBResultSet.h"
#import "ALDBResultColumn.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ALARExecutor <NSObject>

- (instancetype)where:(const ALDBCondition &)conditions;
- (instancetype)orderBy:(const std::list<const ALSQLExpr> &)exprlist;
- (instancetype)limit:(const ALSQLExpr &)limit;
- (instancetype)offset:(const ALSQLExpr &)offset;

- (BOOL)execute;

@end

@protocol ALARFetcher <ALARExecutor>

- (instancetype)select:(const ALDBResultColumnList &)columns distinct:(BOOL)distinct;
- (instancetype)groupBy:(const std::list<const ALSQLExpr> &)exprList;
- (instancetype)having:(const ALSQLExpr &)having;

- (nullable ALDBResultSet *)query;
- (NSInteger)count;

@end

NS_ASSUME_NONNULL_END
