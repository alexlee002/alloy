//
//  ALSQLUpdate.h
//  alloy
//
//  Created by Alex Lee on 25/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALSQLStatement.h"
#import "ALDBTypeDefs.h"
#import "ALDBColumnProperty.h"
#import "ALSQLExpr.h"

@interface ALSQLUpdate : ALSQLStatement

- (instancetype)update:(NSString *)tableName;
- (instancetype)update:(NSString *)tableName onConflict:(ALDBConflictPolicy)policy;

- (instancetype)set:(const std::list<const std::pair<const ALDBColumn, const ALSQLExpr>> &)values;
- (instancetype)setValuesWithDictionary:(NSDictionary<NSString *, id> *)values;

- (instancetype)columns:(const /*std::list<const ALDBColumn>*/ALDBColumnList &)columns;
//- (instancetype)columnProperties:(const std::list<const ALDBColumnProperty> &)columns;

- (instancetype)where:(const ALDBCondition &)conditions;
- (instancetype)orderBy:(const std::list<const ALSQLExpr> &)exprlist;
- (instancetype)limit:(const ALSQLExpr &)limit;
- (instancetype)offset:(const ALSQLExpr &)offset;

@end
