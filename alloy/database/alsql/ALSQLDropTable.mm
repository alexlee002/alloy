//
//  ALSQLDropTable.m
//  alloy
//
//  Created by Alex Lee on 28/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALSQLDropTable.h"
#import "ALSQLValue.h"

@implementation ALSQLDropTable {
    ALSQLClause _clause;
}

- (instancetype)dropTable:(NSString *)tableName {
    _clause.append("DROP TABLE IF EXISTS ").append(tableName);
    return self;
}

- (const ALSQLClause)SQLClause {
    return _clause;
}

@end
