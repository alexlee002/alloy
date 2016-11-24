//
//  ALSQLSelectStatement.h
//  patchwork
//
//  Created by Alex Lee on 2/22/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALSQLStatement.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  @see    http://www.sqlite.org/lang_select.html
 */
@interface ALSQLSelectStatement : ALSQLStatement

/**
 * resultColumns: nil or NSString / ALSQLClause or array of NSString / ALSQLClause
 */
@property(readonly, copy) ALSQLSelectStatement *(^SELECT)(id _Nullable resultColumns);
@property(readonly, copy) ALSQLSelectStatement *(^DISTINCT)(BOOL distinct);
/**
 *  tables: tables or subqueries; NSString / ALSQLClause or array of NSString / ALSQLClause
 */
@property(readonly, copy) ALSQLSelectStatement *(^FROM)(id tablesOrSubqueries);

//clause: NSString or ALSQLClause
@property(readonly, copy) ALSQLSelectStatement *(^WHERE)(id clause);

// exprs: NSString, ALSQLClause or NSArray<NSString *>, NSArray<ALSQLClause *>
@property(readonly, copy) ALSQLSelectStatement *(^GROUP_BY)(id exprs);

// expr: NSString or ALSQLClause
@property(readonly, copy) ALSQLSelectStatement *(^HAVING)(id expr);

// exprs: NSString, ALSQLClause or NSArray<NSString *>, NSArray<ALSQLClause *>
@property(readonly, copy) ALSQLSelectStatement *(^ORDER_BY)(id exprs);
@property(readonly, copy) ALSQLSelectStatement *(^OFFSET)(id expr); // NSNumber or ALSQLClause
@property(readonly, copy) ALSQLSelectStatement *(^LIMIT) (id expr); // NSNumber or ALSQLClause

@end

@interface ALSQLSelectStatement (Helper)
// expres: NSString or ALSQLClause
@property(readonly, copy) NSInteger (^FETCH_COUNT)(id _Nullable expres);

@property(readonly, copy) NSInteger           (^INT_RESULT)();
@property(readonly, copy) BOOL                (^BOOL_RESULT)();
@property(readonly, copy) long long           (^LONGLONG_RESULT)();
@property(readonly, copy) double              (^DOUBLE_RESULT)();

@property(readonly, copy) NSString *_Nullable (^STR_RESULT)();
@property(readonly, copy) NSData   *_Nullable (^DATA_RESULT)();
@property(readonly, copy) NSDate   *_Nullable (^DATE_RESULT)();


@end

NS_ASSUME_NONNULL_END
