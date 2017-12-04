//
//  ALModelSelect.h
//  alloy
//
//  Created by Alex Lee on 07/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALDBResultColumn.h"
#import "ALDBTypeDefines.h"
#import "order_clause.hpp"
#import "ALDBStatement.h"
#import "ALModelORMBase.h"
#import <list>

NS_ASSUME_NONNULL_BEGIN

@interface ALModelSelect<__covariant ObjectType> : ALModelORMBase

- (instancetype)initWithDatabase:(ALDBHandle *)handle
                           table:(NSString *)table
                      modelClass:(Class)modelClass
                      properties:(const ALDBResultColumnList &)results;

+ (instancetype)selectModel:(Class)modelClass properties:(const ALDBResultColumnList &)results;

- (instancetype)where:(const ALDBCondition &)condition;

- (instancetype)orderBy:(const std::list<const aldb::OrderClause> &)list;

- (instancetype)limit:(const ALDBExpr &)limit;

- (instancetype)offset:(const ALDBExpr &)offset;

- (instancetype)groupBy:(const std::list<const ALDBExpr> &)list;

- (instancetype)having:(const ALDBExpr &)expr;

- (nullable ALDBResultSet *)executeQuery;

- (nullable NSEnumerator<ObjectType> *)objectEnumerator;

- (nullable NSArray<ObjectType> *)allObjects;

@end
NS_ASSUME_NONNULL_END

