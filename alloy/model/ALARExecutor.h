//
//  ALARExecutor.h
//  alloy
//
//  Created by Alex Lee on 25/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ALARExecutor <NSObject>

- (instancetype)where:(const ALDBCondition &)conditions;
- (instancetype)orderBy:(const std::list<const ALSQLExpr> &)exprlist;
- (instancetype)limit:(const ALSQLExpr &)limit;
- (instancetype)offset:(const ALSQLExpr &)offset;

@end

@protocol ALARFetcher <ALARExecutor>

- (instancetype)groupBy:(const std::list<const ALSQLExpr> &)exprList;
- (instancetype)having:(const ALSQLExpr &)having;

@end
