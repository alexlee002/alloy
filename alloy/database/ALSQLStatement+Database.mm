//
//  ALSQLStatement+Database.m
//  alloy
//
//  Created by Alex Lee on 11/09/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALSQLStatement+Database.h"
#import "ALDatabase+Statement.h"
#import "statement_recyclable.hpp"
#import "ALUtilitiesHeader.h"
#import <objc/runtime.h>

@implementation ALSQLStatement (Database)

- (void)setDatabase:(ALDatabase *)db {
    objc_setAssociatedObject(self, @selector(database), db, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (ALDatabase *)database {
    return ALCastToTypeOrNil(objc_getAssociatedObject(self, @selector(database)), ALDatabase);
}

+ (instancetype)statementWithDatabase:(ALDatabase *)db {
    ALSQLStatement *stmt = [ALSQLStatement statement];
    [stmt setDatabase:db];
    return stmt;
}

- (BOOL)execute {
    ALDatabase *db = self.database;
    if (!db) {
        return NO;
    }
    return [db execute:self];
}

@end

@implementation ALSQLSelect (Database)

- (ALDBResultSet *)query {
    return [[self database] select:self];
}

- (NSInteger)count {
    ALDBResultSet *rs = [[self select:{ ALSQLExpr(ALDBColumn::s_any).count() } distinct:NO] query];
    if ([rs next]) {
        return [rs integerValueForColumnIndex:0];
    }
    return 0;
}

@end
