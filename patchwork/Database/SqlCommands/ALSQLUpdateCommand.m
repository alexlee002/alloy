//
//  ALSQLUpdateCommand.m
//  patchwork
//
//  Created by Alex Lee on 2/22/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALSQLUpdateCommand.h"
#import "NSString+Helper.h"
#import "UtilitiesHeader.h"
#import "ALSQLCondition.h"
#import "BlocksKit.h"

NS_ASSUME_NONNULL_BEGIN
@implementation ALSQLUpdateCommand {
    NSString            *_tableStatement;
    NSString            *_policy;
    NSMutableDictionary *_values;
    NSMutableArray      *_rawValues;
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

- (ALSQLUpdateConditionBlock)RAW_SET {
    return ^ALSQLUpdateCommand *_Nonnull(ALSQLCondition *_Nonnull expression) {
        expression = castToTypeOrNil(expression, ALSQLCondition);
        if (expression) {
            @synchronized(self) {
                if (_rawValues == nil) {
                    _rawValues = [NSMutableArray array];
                }
            }
            [_rawValues addObject:expression.build];
        }
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
    if (_values.count == 0 && _rawValues.count == 0) {
        NSAssert(NO, @"no update values specified.");
        return nil;
    }
    
    [sql appendString:@" SET "];
    _sqlArgs = [NSMutableArray arrayWithCapacity:_values.count];
    
    if (_values.count > 0) {
        NSMutableArray *updateClauses = [NSMutableArray array];
        [_values bk_each:^(NSString *colName, id expr) {
            [updateClauses addObject:[colName stringByAppendingString:@"=?"]];
            [(NSMutableArray *)_sqlArgs addObject:expr];
        }];
        [sql appendString:[updateClauses componentsJoinedByString:@", "]];
        
        if (_rawValues.count > 0) {
            [sql appendString:@", "];
        }
    }
    
    if (_rawValues.count > 0) {
        [_rawValues bk_each:^(ALSQLCondition *exp) {
            [sql appendString:exp.sqlClause];
            [sql appendString:@", "];
            [(NSMutableArray *)_sqlArgs addObjectsFromArray:exp.sqlArguments];
        }];
        NSRange range = [sql rangeOfString:@", " options:NSBackwardsSearch];
        range.length = sql.length - range.location;
        [sql deleteCharactersInRange:range];
    }
    
    // WHERE
    if (!isEmptyString(_where.sqlClause)) {
        [sql appendString: @" WHERE "];
        [sql appendString:_where.sqlClause];
    }
    
    [(NSMutableArray *)_sqlArgs addObjectsFromArray:_where.sqlArguments];
    return [sql copy];
}

@end

NS_ASSUME_NONNULL_END
