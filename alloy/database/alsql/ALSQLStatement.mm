//
//  ALSQLStatement.m
//  alloy
//
//  Created by Alex Lee on 19/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALSQLStatement.h"

@implementation ALSQLStatement

+ (instancetype)statement {
    return [[self alloc] init];
}

- (const ALSQLClause)SQLClause {
    return ALSQLClause();
}

@end
