//
//  ALModelUpdate.h
//  alloy
//
//  Created by Alex Lee on 10/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALDBTypeDefines.h"
#import "order_clause.hpp"
#import "ALDBStatement.h"
#import "ALDBProperty.h"

NS_ASSUME_NONNULL_BEGIN
@interface ALModelUpdate : NSObject

+ (instancetype)updateModel:(Class)modelClass
                 properties:(const ALDBPropertyList &)propertiesToUpdate
                 onConflict:(ALDBConflictPolicy)onConflict;

- (instancetype)where:(const ALDBCondition &)condition;

- (instancetype)orderBy:(const std::list<const aldb::OrderClause> &)list;

- (instancetype)limit:(const ALDBExpr &)limit;

- (instancetype)offset:(const ALDBExpr &)offset;

- (BOOL)executeWithObject:(id)model;

- (NSInteger)changes;

- (nullable ALDBStatement *)preparedStatement;

@end

NS_ASSUME_NONNULL_END
