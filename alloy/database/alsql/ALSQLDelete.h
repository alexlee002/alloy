//
//  ALSQLDelete.h
//  alloy
//
//  Created by Alex Lee on 26/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALSQLStatement.h"
#import "ALSQLExpr.h"

@interface ALSQLDelete : ALSQLStatement

- (instancetype)deleteFrom:(NSString *)tableName;
- (instancetype)where:(const ALDBCondition &)conditions;
- (instancetype)orderBy:(const std::list<const ALSQLExpr> &)exprlist;
- (instancetype)limit:(const ALSQLExpr &)limit;
- (instancetype)offset:(const ALSQLExpr &)offset;

@end
