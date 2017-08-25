//
//  ALDatabase+Statement.m
//  alloy
//
//  Created by Alex Lee on 23/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDatabase+Statement.h"
#import "ALDatabase+CoreDB.h"

@implementation ALDatabase (Statement)

- (nullable ALDBResultSet *)query:(ALSQLSelect *)select {
    const ALSQLClause clause = [select SQLClause];
    return [self query:clause.sqlString() args:clause.sqlArgs()];
}

- (BOOL)execute:(ALSQLStatement *)stmt {
    const ALSQLClause clause = [stmt SQLClause];
    return [self exec:clause.sqlString() args:clause.sqlArgs()];
}

@end
