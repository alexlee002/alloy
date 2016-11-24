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
#import "ALSQLClause+SQLFunctions.h"
#import "SafeBlocksChain.h"

#define __ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_ARRAY_CLAUSE(stmt_class, prop_name, _ivar_name)   \
- (stmt_class *(^)(id clauses))prop_name {                                                  \
    return ^stmt_class *(id clauses) {                                                      \
        __ALSQLSTMT_BLOCK_CHAIN_OBJ_VERIFY();                                               \
                                                                                            \
        if ([clauses isKindOfClass:NSString.class]) {                                       \
            _ivar_name = @[[clauses SQLClause]];                                                \
        }                                                                                   \
        else if ([clauses isKindOfClass:ALSQLClause.class]) {                               \
            _ivar_name = @[(ALSQLClause *)clauses];                                         \
        }                                                                                   \
        else if ([clauses isKindOfClass:NSArray.class]) {                                   \
            NSMutableArray<ALSQLClause *> *cols = [NSMutableArray arrayWithCapacity:((NSArray *)clauses).count];    \
            [clauses enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {         \
                if ([obj isKindOfClass:NSString.class]) {                                   \
                    [cols addObject:[obj SQLClause]];                                           \
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



- (nullable ALSQLClause *)SQLClause {
    __ALSQLSTMT_BUILD_SQL_VERIFY();
    
    ALSQLClause *sql = [@"SELECT " SQLClause];
    
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


#define __ALSQL_SELECT_EXT_BLOCK_IMP(TYPE, BLOCK_NAME, RS_SEL)  \
    - (TYPE (^)())BLOCK_NAME {                                  \
        return ^TYPE {                                          \
            ValidBlocksChainObjectOrReturn(self, (TYPE)(0x0));  \
                                                                \
            __block TYPE result = (TYPE)(0x0);                  \
            self.EXECUTE_QUERY(^(FMResultSet *rs) {             \
                if ([rs next]) {                                \
                    result = [rs RS_SEL:0];                     \
                }                                               \
            });                                                 \
            return result;                                      \
        };                                                      \
    }

@implementation ALSQLSelectStatement (Helper)

- (NSInteger (^)(id expres))FETCH_COUNT {
    return ^NSInteger (id expres) {
        ValidBlocksChainObjectOrReturn(self, 0);
        
        __block NSInteger count = 0;
        self.SELECT(SQL_COUNT(expres)).EXECUTE_QUERY(^(FMResultSet *rs){
            if ([rs next]) {
                count = [rs intForColumnIndex:0];
            }
        });
        return count;
    };
}

__ALSQL_SELECT_EXT_BLOCK_IMP(NSInteger, INT_RESULT,      intForColumnIndex);
__ALSQL_SELECT_EXT_BLOCK_IMP(BOOL,      BOOL_RESULT,     boolForColumnIndex);
__ALSQL_SELECT_EXT_BLOCK_IMP(long long, LONGLONG_RESULT, longLongIntForColumnIndex);
__ALSQL_SELECT_EXT_BLOCK_IMP(double,    DOUBLE_RESULT,   doubleForColumnIndex);

__ALSQL_SELECT_EXT_BLOCK_IMP(NSString *_Nullable, STR_RESULT,  stringForColumnIndex);
__ALSQL_SELECT_EXT_BLOCK_IMP(NSData *_Nullable,   DATA_RESULT, dataForColumnIndex);
__ALSQL_SELECT_EXT_BLOCK_IMP(NSDate *_Nullable,   DATE_RESULT, dateForColumnIndex);

@end

