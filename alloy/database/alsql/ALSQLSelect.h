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

- (const ALDBResultColumnList &)resultColumns;

- (instancetype)select:(const ALDBResultColumnList &)columns distinct:(BOOL)distinct;
- (instancetype)from:(NSString *)table;
- (instancetype)where:(const ALDBCondition &)conditions;
- (instancetype)groupBy:(const std::list<const ALSQLExpr> &)exprList;
- (instancetype)having:(const ALSQLExpr &)having;
- (instancetype)orderBy:(const std::list<const ALSQLExpr> &)exprlist;
- (instancetype)limit:(const ALSQLExpr &)limit;
- (instancetype)offset:(const ALSQLExpr &)offset;

@end

NS_ASSUME_NONNULL_END

#endif
