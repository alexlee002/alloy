//
//  ALSQLSelect.h
//  alloy
//
//  Created by Alex Lee on 19/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALSQLStatement.h"

#ifdef __cplusplus
#import <list>
#import "ALDBResultColumn.h"

NS_ASSUME_NONNULL_BEGIN

@interface ALSQLSelect : ALSQLStatement

- (const std::list<const ALDBResultColumn> &)resultColumns;

- (instancetype)select:(const std::list<const ALDBResultColumn> &)columns distinct:(BOOL)distinct;
- (instancetype)from:(NSString *)table;
- (instancetype)where:(const ALDBCondition &)conditions;
- (instancetype)groupBy:(const std::list<const ALSQLExpr> &)exprList;
- (instancetype)having:(const ALSQLExpr &)having;
- (instancetype)limit:(const ALSQLExpr &)limit;
- (instancetype)offset:(const ALSQLExpr &)offset;

@end

NS_ASSUME_NONNULL_END

#endif
