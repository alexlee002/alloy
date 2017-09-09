//
//  ALSQLInsert.h
//  alloy
//
//  Created by Alex Lee on 25/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALSQLStatement.h"
#import "ALDBTypeDefs.h"
#import "ALDBColumn.h"
#import "ALDBColumnProperty.h"
#import "ALSQLSelect.h"

@interface ALSQLInsert : ALSQLStatement

- (instancetype)insertInto:(NSString *)tableName;
- (instancetype)insertInto:(NSString *)tableName onConflict:(ALDBConflictPolicy)policy;
- (instancetype)insertInto:(NSString *)table
                   columns:(const std::list<const ALDBColumn> &)columns
                onConflict:(ALDBConflictPolicy)policy;

//- (instancetype)columnProperties:(const std::list<const ALDBColumnProperty> &)columns;

- (instancetype)values:(const std::list<const ALSQLExpr> &)exprlist;
- (instancetype)valuesWithDictionary:(NSDictionary<NSString *, id> *)dict;
- (instancetype)valuesWithSelection:(ALSQLSelect *)select;
- (instancetype)usingDefaultValues;

@end
