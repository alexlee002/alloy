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

- (ALSQLSelectBlockStrArray)SELECT {
    return ^ALSQLSelectCommand *_Nonnull(NSArray<NSString *> *_Nullable strs) {
        _columns = [strs copy];
        return self;
    };
}

- (ALSQLSelectBlockString)FROM {
    return ^ALSQLSelectCommand *_Nonnull(NSString * str) {
        _from = [str copy];
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

- (ALSQLSelectBlockStrArray)ORDER_BY {
    return ^ALSQLSelectCommand *_Nonnull(NSArray<NSString *> *_Nullable strs) {
        _orderBy = [strs copy];
        return self;
    };
}

- (ALSQLSelectBlockStrArray)GROUP_BY {
    return ^ALSQLSelectCommand *_Nonnull(NSArray<NSString *> *_Nullable strs) {
        _groupBy = [strs copy];
        return self;
    };
}

- (ALSQLSelectBlockNumArray)LIMIT {
    return ^ALSQLSelectCommand *_Nonnull(NSArray<NSNumber *> *_Nullable nums) {
        nums = [[nums subarrayToIndex:3] bk_select:^BOOL(NSNumber *num) {
            return [num isKindOfClass:[NSNumber class]];
        }];
        if (nums.count == 0) {
            NSAssert(NO, @"SELECT: illegal 'LIMIT' clause.");
            _limit = nil;
        } else {
            _limit = [nums componentsJoinedByString:@", "];
        }
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
    if (!isEmptyString(_limit)) {
        [sql appendString:@" LIMIT "];
        [sql appendString:_limit];
    }
    
    _sqlArgs = _where.sqlArguments;
    return [sql copy];
}
@end
