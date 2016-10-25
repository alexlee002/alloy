//
//  ALSQLUpdateCommand.h
//  patchwork
//
//  Created by Alex Lee on 2/22/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALSQLStatement.h"


NS_ASSUME_NONNULL_BEGIN

/**
 *  @see http://www.sqlite.org/lang_update.html
 */
@interface ALSQLUpdateStatement : ALSQLStatement

// qualifiedTableName: NSString or ALSQLClause
@property(readonly, copy) ALSQLUpdateStatement *(^UPDATE)       (id qualifiedTableName);
@property(readonly, copy) ALSQLUpdateStatement *(^OR_REPLACE)   (BOOL yesOrno);
@property(readonly, copy) ALSQLUpdateStatement *(^OR_ROLLBACK)  (BOOL yesOrno);
@property(readonly, copy) ALSQLUpdateStatement *(^OR_ABORT)     (BOOL yesOrno);
@property(readonly, copy) ALSQLUpdateStatement *(^OR_FAIL)      (BOOL yesOrno);
@property(readonly, copy) ALSQLUpdateStatement *(^OR_IGNORE)    (BOOL yesOrno);

// clauses: NSDictionary, ALSQLClause or NSArray<ALSQLClause *>
@property(readonly, copy) ALSQLUpdateStatement *(^SET)          (id clauses);

//clause: NSString or ALSQLClause
@property(readonly, copy) ALSQLUpdateStatement *(^WHERE)(id clause);
// exprs: NSString, ALSQLClause or NSArray<NSString *>, NSArray<ALSQLClause *>
@property(readonly, copy) ALSQLUpdateStatement *(^ORDER_BY)(id exprs);
@property(readonly, copy) ALSQLUpdateStatement *(^OFFSET)(id expr); // NSNumber or ALSQLClause
@property(readonly, copy) ALSQLUpdateStatement *(^LIMIT) (id expr); // NSNumber or ALSQLClause

@end

NS_ASSUME_NONNULL_END
