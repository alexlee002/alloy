//
//  ALSQLCreateIndex.h
//  alloy
//
//  Created by Alex Lee on 28/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALSQLStatement.h"
#import "ALDBIndexedColumn.h"

@interface ALSQLCreateIndex : ALSQLStatement
- (instancetype)createIndex:(NSString *)indexName unique:(BOOL)unique ifNotExists:(BOOL)ifNotExists;

- (instancetype)onTable:(NSString *)tableName columns:(const std::list<const ALDBIndexedColumn> &)columns;

- (instancetype)where:(const ALSQLExpr &)where;
@end
