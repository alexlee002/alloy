//
//  ALSQLStatement+Database.h
//  alloy
//
//  Created by Alex Lee on 11/09/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALSQLStatement.h"
#import "ALSQLSelect.h"
#import "ALDBResultSet.h"
#import "ALDatabase+CoreDB.h"
#import "ALARExecutor.h"

@interface ALSQLStatement (Database)<ALARExecutor>

+ (instancetype)statementWithDatabase:(ALDatabase *)db;
- (BOOL)execute;

@end

@interface ALSQLSelect (Database) <ALARFetcher>

- (ALDBResultSet *)query;
- (NSInteger)count;

@end
