//
//  ALSQLDropIndex.m
//  alloy
//
//  Created by Alex Lee on 28/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALSQLDropIndex.h"
#import "ALSQLValue.h"

@implementation ALSQLDropIndex {
    ALSQLClause _clause;
}

- (instancetype)dropIndex:(NSString *)indexName {
    _clause.append("DROP INDEX IF EXISTS ").append(indexName);
    return self;
}

- (const ALSQLClause)SQLClause {
    return _clause;
}

@end
