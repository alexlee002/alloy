//
//  ALSQLDeleteStatement.m
//  patchwork
//
//  Created by Alex Lee on 2/23/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALSQLDeleteStatement.h"
#import "NSString+Helper.h"
#import "ALSQLClause+SQLOperation.h"
#import "ALSQLStatementHelpers_private.h"
#import "SafeBlocksChain.h"

@implementation ALSQLDeleteStatement {
    ALSQLClause *_qualifiedTableName;
    ALSQLClause *_whereClause;
    ALSQLClause *_orderClause;
    ALSQLClause *_limitClause;
    ALSQLClause *_offsetClause;
    
    ALSQLClause *_SQLClause;
    BOOL         _needReBuild;
}

- (ALSQLDeleteStatement *(^)())DELETE {
    return ^ALSQLDeleteStatement *() {
        __ALSQLSTMT_BLOCK_CHAIN_OBJ_VERIFY();
        return self;
    };
}

__ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_FROM    (ALSQLDeleteStatement, _qualifiedTableName);
__ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_WHERE   (ALSQLDeleteStatement, _whereClause);
__ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_ORDER_BY(ALSQLDeleteStatement, _orderClause);
__ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_LIMIT   (ALSQLDeleteStatement, _limitClause);
__ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_OFFSET  (ALSQLDeleteStatement, _offsetClause);

- (nullable ALSQLClause *)SQLClause {
    __ALSQLSTMT_BUILD_SQL_VERIFY();
    
    ALSQLClause *sql = [@"DELETE" SQLClause];
    
    if ([_qualifiedTableName isValid]) {
        [sql append:_qualifiedTableName withDelimiter:@" FROM "];
    } else {
        NSAssert(NO, @"*** 'qualified-table-name' must be specified !!!");
    }
    
    if ([_whereClause isValid]) {
        [sql append:_whereClause withDelimiter:@" WHERE "];
    }
    
    if ([_orderClause isValid]) {
        [sql append:_orderClause withDelimiter:@" ORDER BY "];
    }
    
    if ([_limitClause isValid]) {
        [sql append:_limitClause withDelimiter:@" LIMIT "];
    }
    
    if ([_offsetClause isValid]) {
        [sql append:_offsetClause withDelimiter:@" OFFSET "];
    }
    
    _SQLClause = sql;
    _needReBuild = NO;
    
    return _SQLClause;
}

@end
