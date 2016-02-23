//
//  ALSQLUpdateCommand.m
//  patchwork
//
//  Created by Alex Lee on 2/22/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALSQLUpdateCommand.h"
#import "StringHelper.h"
#import "UtilitiesHeader.h"
#import "ALSQLCondition.h"
#import "BlocksKit.h"

NS_ASSUME_NONNULL_BEGIN
@implementation ALSQLUpdateCommand {
    NSString            *_tableStatement;
    NSString            *_policy;
    NSMutableDictionary *_values;
}

- (ALSQLUpdateBlockString)UPDATE {
    return ^ALSQLUpdateCommand *_Nonnull(NSString *_Nonnull table) {
        _tableStatement = [table copy];
        return self;
    };
}

- (ALSQLUpdateBlockString)POLICY {
    return ^ALSQLUpdateCommand *_Nonnull(NSString *_Nonnull policy) {
        _policy = [policy copy];
        return self;
    };
}

- (ALSQLUpdateBlockDict)VALUES {
    return ^ALSQLUpdateCommand *_Nonnull(NSDictionary *_Nonnull values) {
        _values = [values mutableCopy];
        return self;
    };
}

- (ALSQLUpdateBlockStrId)SET {
    return ^ALSQLUpdateCommand *_Nonnull(NSString *_Nonnull str, id obj) {
        @synchronized(self) {
            if (_values == nil) {
                _values = [NSMutableDictionary dictionary];
            }
        }
        _values[str] = wrapNil(obj);
        return self;
    };
}

- (ALSQLUpdateConditionBlock)WHERE {
    return ^ALSQLUpdateCommand *_Nonnull(ALSQLCondition *_Nonnull condition) {
        [condition build];
        self->_where = condition;
        return self;
    };
}

- (nullable NSString *)sql {
    NSMutableString *sql = [@"UPDATE " mutableCopy];
    if (!isEmptyString(_policy)) {
        [sql appendString:_policy];
        [sql appendString:@" "];
    }
    
    if (isEmptyString(_tableStatement)) {
        NSAssert(NO, @"UPDATE: no 'qualified-table-name' specified.");
        return nil;
    }
    [sql appendString:_tableStatement];
    
    // SET VALUES
    if (_values.count == 0) {
        NSAssert(NO, @"no update values specified.");
        return nil;
    }
    
    [sql appendString:@" SET "];
    NSMutableArray *updateClauses = [NSMutableArray array];
    _sqlArgs = [NSMutableArray arrayWithCapacity:_values.count];
    [_values bk_each:^(NSString *colName, id expr) {
        [updateClauses addObject:[colName stringByAppendingString:@"=?"]];
        [(NSMutableArray *)_sqlArgs addObject:expr];
    }];
    [sql appendString:[updateClauses componentsJoinedByString:@", "]];
    
    // WHERE
    if (!isEmptyString(_where.sqlCondition)) {
        [sql appendString: @" WHERE "];
        [sql appendString:_where.sqlCondition];
    }
    
    [(NSMutableArray *)_sqlArgs addObjectsFromArray:_where.conditionArgs];
    return [sql copy];
}

@end

NS_ASSUME_NONNULL_END
