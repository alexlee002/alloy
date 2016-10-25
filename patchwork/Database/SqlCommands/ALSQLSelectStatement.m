//
//  ALSQLSelectStatement.m
//  patchwork
//
//  Created by Alex Lee on 2/22/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALSQLSelectStatement.h"
#import "NSString+Helper.h"
#import "UtilitiesHeader.h"
#import "ALSQLStatementHelpers.h"
#import "ALSQLClause+SQLOperation.h"
#import "SafeBlocksChain.h"

#define __ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_ARRAY_CLAUSE(stmt_class, prop_name, _ivar_name)   \
- (stmt_class *(^)(id clauses))prop_name {                                                  \
    return ^stmt_class *(id clauses) {                                                      \
        __ALSQLSTMT_BLOCK_CHAIN_OBJ_VERIFY();                                               \
                                                                                            \
        if ([clauses isKindOfClass:NSString.class]) {                                       \
            _ivar_name = @[[clauses toSQL]];                                                \
        }                                                                                   \
        else if ([clauses isKindOfClass:ALSQLClause.class]) {                               \
            _ivar_name = @[(ALSQLClause *)clauses];                                         \
        }                                                                                   \
        else if ([clauses isKindOfClass:NSArray.class]) {                                   \
            NSMutableArray<ALSQLClause *> *cols = [NSMutableArray arrayWithCapacity:((NSArray *)clauses).count];    \
            [clauses enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {         \
                if ([obj isKindOfClass:NSString.class]) {                                   \
                    [cols addObject:[obj toSQL]];                                           \
                }                                                                           \
                else if ([obj isKindOfClass:ALSQLClause.class]) {                           \
                    [cols addObject:(ALSQLClause *)obj];                                    \
                }                                                                           \
            }];                                                                             \
            _ivar_name = cols;                                                              \
        }                                                                                   \
        _needReBuild = YES;                                                                 \
        return self;                                                                        \
    };                                                                                      \
}


@implementation ALSQLSelectStatement {
    NSArray<ALSQLClause *> *_resultColumns;
    NSArray<ALSQLClause *> *_tablesOrSubQueries;
    BOOL             _distinct;
    ALSQLClause     *_where;
    ALSQLClause     *_groupBy;
    ALSQLClause     *_having;
    ALSQLClause     *_orderBy;
    ALSQLClause     *_offset;
    ALSQLClause     *_limit;
    
    ALSQLClause *_SQLClause;
    BOOL         _needReBuild;
}


- (ALSQLSelectStatement *(^)(BOOL distinct))DISTINCT {
    return ^ALSQLSelectStatement *(BOOL distinct) {
        __ALSQLSTMT_BLOCK_CHAIN_OBJ_VERIFY();
        _distinct = distinct;
        _needReBuild = YES;
        return self;
    };
}

__ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_ARRAY_CLAUSE(ALSQLSelectStatement, SELECT, _resultColumns);
__ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_ARRAY_CLAUSE(ALSQLSelectStatement, FROM,   _tablesOrSubQueries);

__ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_WHERE     (ALSQLSelectStatement, _where);
__ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_GROUP_BY  (ALSQLSelectStatement, _groupBy);
__ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_HAVING    (ALSQLSelectStatement, _having);
__ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_ORDER_BY  (ALSQLSelectStatement, _orderBy);
__ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_LIMIT     (ALSQLSelectStatement, _limit);
__ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_OFFSET    (ALSQLSelectStatement, _offset);



- (nullable ALSQLClause *)toSQL {
    __ALSQLSTMT_BUILD_SQL_VERIFY();
    
    ALSQLClause *sql = [@"SELECT " toSQL];
    
    if (_distinct) {
        [sql append:@"DISTINCT " argValues:nil withDelimiter:nil];
    }
    
    if (_resultColumns.count > 0) {
        __ALSQLSTMT_JOIN_CLAUSE_ARRAY(sql, _resultColumns, @", ");
    } else {
        [sql append:@"*" argValues:nil withDelimiter:nil];
    }
    
    if (_tablesOrSubQueries.count > 0) {
        [sql append:@" FROM " argValues:nil withDelimiter:nil];
        __ALSQLSTMT_JOIN_CLAUSE_ARRAY(sql, _tablesOrSubQueries, @", ");
    }

    if ([_where isValid]) {
        [sql append:_where withDelimiter:@" WHERE "];
    }
    
    if ([_groupBy isValid]) {
        [sql append:_groupBy withDelimiter:@" GROUP BY "];
    }
    
    if ([_having isValid]) {
        [sql append:_having withDelimiter:@" HAVING "];
    }
    
    if ([_orderBy isValid]) {
        [sql append:_orderBy withDelimiter:@" ORDER BY "];
    }
    
    if ([_limit isValid]) {
        [sql append:_limit withDelimiter:@" LIMIT "];
    }
    
    if ([_offset isValid]) {
        [sql append:_offset withDelimiter:@" OFFSET "];
    }

    _SQLClause = sql;
    _needReBuild = NO;
    
    return _SQLClause;
}


@end

