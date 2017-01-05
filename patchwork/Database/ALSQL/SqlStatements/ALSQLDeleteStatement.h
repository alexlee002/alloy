//
//  ALSQLDeleteStatement.h
//  patchwork
//
//  Created by Alex Lee on 2/23/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALSQLStatement.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @see http://www.sqlite.org/lang_delete.html
 */
@interface ALSQLDeleteStatement : ALSQLStatement

@property(readonly, copy) ALSQLDeleteStatement *(^DELETE)();

// qualifiedTableName: NSString or ALSQLClause
@property(readonly, copy) ALSQLDeleteStatement *(^FROM)  (id qualifiedTableName);
// whereClause: NSString or ALSQLClause
@property(readonly, copy) ALSQLDeleteStatement *(^WHERE) (id whereClause);

// exprs: NSString, ALSQLClause or NSArray<NSString *>, NSArray<ALSQLClause *>
@property(readonly, copy) ALSQLDeleteStatement *(^ORDER_BY)(id exprs);
@property(readonly, copy) ALSQLDeleteStatement *(^OFFSET)(id _Nullable expr); // NSNumber or ALSQLClause
@property(readonly, copy) ALSQLDeleteStatement *(^LIMIT) (id _Nullable expr); // NSNumber or ALSQLClause

@end

NS_ASSUME_NONNULL_END
