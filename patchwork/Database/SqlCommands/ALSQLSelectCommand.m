//
//  ALSQLSelectCommand.m
//  patchwork
//
//  Created by Alex Lee on 2/22/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALSQLSelectCommand.h"
#import "NSString+Helper.h"
#import "UtilitiesHeader.h"
#import "ALSQLCondition.h"
#import "NSArray+ArrayExtensions.h"
#import "BlocksKit.h"

@implementation ALSQLSelectCommand {
    NSString                   *_from;
    NSMutableArray<NSString *> *_columns;
    NSMutableArray<NSString *> *_orderBy;
    NSMutableArray<NSString *> *_groupBy;
    NSMutableArray<NSString *> *_havings;
    
    NSString                   *_rawWhere;
}

- (nullable NSArray<NSString *> *)columns {
    return [_columns copy];
}

- (ALSQLSelectBlockArray)SELECT {
    return ^ALSQLSelectCommand *_Nonnull(NSArray *_Nullable strs) {
        _columns = [[[strs bk_map:^NSString *(id obj) {
            __stringifyExpressionOrReturnNil(obj);
            return obj;
        }] bk_reject:^BOOL(id obj) {
            return obj == NSNull.null;
        }] mutableCopy];
        return self;
    };
}

- (ALSQLSelectBlockId)FROM {
    return ^ALSQLSelectCommand *_Nonnull(id expression) {
        if ([expression isKindOfClass:[NSString class]]) {
            _from = [expression copy];
        } else if ([expression isKindOfClass:[ALSQLSelectCommand class]]) {
            ALSQLSelectCommand *subSelect = (ALSQLSelectCommand *)expression;
            _from = [NSString stringWithFormat:@"(%@)", subSelect.sql];
            if (_sqlArgs == nil) {
                _sqlArgs = subSelect.sqlArgs;
            } else {
                _sqlArgs = [_sqlArgs arrayByAddingObjectsFromArray:subSelect.sqlArgs];
            }
        }
        
        return self;
    };
}

- (ALSQLSelectConditionBlock)WHERE {
    return ^ALSQLSelectCommand *_Nonnull(ALSQLCondition *_Nullable condition) {
        [condition build];
        self->_where = condition;
        return self;
    };
}

- (ALSQLSelectBlockArray)ORDER_BYS {
    return ^ALSQLSelectCommand *_Nonnull(NSArray *_Nullable strs) {
        strs = [[strs bk_map:^NSString *(id obj) {
            __stringifyExpressionOrReturnNil(obj);
            return obj;
        }] bk_reject:^BOOL(id obj) {
            return obj == NSNull.null;
        }];
        
        if (_orderBy == nil) {
            _orderBy = [strs mutableCopy];
        } else {
            [_orderBy addObjectsFromArray:strs];
        }
        return self;
    };
}

- (ALSQLSelectBlockArray)GROUP_BYS {
    return ^ALSQLSelectCommand *_Nonnull(NSArray *_Nullable strs) {
        strs = [[strs bk_map:^NSString *(id obj) {
            __stringifyExpressionOrReturnNil(obj);
            return obj;
        }] bk_reject:^BOOL(id obj) {
            return obj == NSNull.null;
        }];
        
        if (_groupBy == nil) {
            _groupBy = [strs mutableCopy];
        } else {
            [_groupBy addObjectsFromArray:strs];
        }
        return self;
    };
}

- (ALSQLSelectBlockId)ORDER_BY {
    return ^ALSQLSelectCommand *_Nonnull (id _Nullable value) {
        value = [value isKindOfClass:[ALSQLExpression class]] ? ((ALSQLExpression *)value).stringify : [value stringify];
        if (!isEmptyString(value)) {
            if (_orderBy == nil) {
                _orderBy = [@[value] mutableCopy];
            } else {
                [_orderBy addObject:value];
            }
        }
        return self;
    };
}

- (ALSQLSelectBlockId)GROUP_BY {
    return ^ALSQLSelectCommand *_Nonnull (id _Nullable value) {
        value = [value isKindOfClass:[ALSQLExpression class]] ? ((ALSQLExpression *)value).stringify : [value stringify];
        if (!isEmptyString(value)) {
            if (_groupBy == nil) {
                _groupBy = [@[value] mutableCopy];
            } else {
                [_groupBy addObject:value];
            }
        }
        return self;
    };
}

- (ALSQLSelectBlockInt)LIMIT {
    return ^ALSQLSelectCommand *_Nonnull(NSInteger num) {
        _limit = @(num);
        return self;
    };
}

- (ALSQLSelectBlockInt)OFFSET {
    return ^ALSQLSelectCommand *_Nonnull(NSInteger num) {
        _offset = @(num);
        return self;
    };
}

- (ALSQLSelectRawWhereBLock)RAW_WHERE {
    return ^ALSQLSelectCommand *_Nonnull(NSString *_Nullable str, NSArray *_Nullable args) {
        _rawWhere = [str copy];
        _sqlArgs  = [args copy];
        return self;
    };
}


- (nullable NSString *)sql {
    NSMutableString *sql = [NSMutableString stringWithString:@"SELECT "];
    if (_columns.count > 0) {
        [sql appendString:[_columns componentsJoinedByString:@", "]];
    } else {
        [sql appendString:@"*"];
    }
    
    // FROM
    if (isEmptyString(_from)) {
        NSAssert(NO, @"SELECT: no table name specified.");
        return nil;
    }
    [sql appendString: @" FROM "];
    [sql appendString:_from];
    
    if (!isEmptyString(_rawWhere)) {
        [sql appendString: @" WHERE "];
        [sql appendString:_rawWhere];
        
        return [sql copy];
    }
    
    // WHERE
    if (!isEmptyString(_where.sqlClause)) {
        [sql appendString: @" WHERE "];
        [sql appendString:_where.sqlClause];
    }
    
    // GROUP BY
    if (_groupBy.count > 0) {
        [sql appendString: @" GROUP BY "];
        [sql appendString: [_groupBy componentsJoinedByString:@", "]];
    }
    
    // ORDER BY
    if (_orderBy.count > 0) {
        [sql appendString: @" ORDER BY "];
        [sql appendString: [_orderBy componentsJoinedByString:@", "]];
    }
    
    // LIMIT
    if (_limit != nil) {
        [sql appendString:@" LIMIT "];
        if (_offset != nil) {
            [sql appendFormat:@"%d, %d", _offset.intValue, _limit.intValue];
        } else {
            [sql appendFormat:@"%d", _limit.intValue];
        }
    }
    
    _sqlArgs = _sqlArgs == nil ? _where.sqlArguments : [_sqlArgs arrayByAddingObjectsFromArray:_where.sqlArguments];
    return [sql copy];
}
@end
