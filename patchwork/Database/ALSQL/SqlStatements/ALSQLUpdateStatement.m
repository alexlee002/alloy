//
//  ALSQLUpdateCommand.m
//  patchwork
//
//  Created by Alex Lee on 2/22/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALSQLUpdateStatement.h"
#import "NSString+Helper.h"
#import "ALUtilitiesHeader.h"
#import "__ALSQLStatementHelpers.h"
#import "ALSQLClause+SQLOperation.h"
#import <BlocksKit.h>
#import "SafeBlocksChain.h"

NS_ASSUME_NONNULL_BEGIN

@implementation ALSQLUpdateStatement {
    ALSQLClause *_qualifiedTableName;
    NSString    *_policy;
    NSMutableArray<ALSQLClause *> *_setClauses;
    ALSQLClause *_where;
    ALSQLClause *_orderBy;
    ALSQLClause *_limit;
    ALSQLClause *_offset;
    
    ALSQLClause *_SQLClause;
    BOOL         _needReBuild;
}

__ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_POLICY(ALSQLUpdateStatement, OR_FAIL,     @"OR FAIL");
__ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_POLICY(ALSQLUpdateStatement, OR_ABORT,    @"OR ABORT");
__ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_POLICY(ALSQLUpdateStatement, OR_IGNORE,   @"OR IGNORE");
__ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_POLICY(ALSQLUpdateStatement, OR_REPLACE,  @"OR REPLACE");
__ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_POLICY(ALSQLUpdateStatement, OR_ROLLBACK, @"OR ROLLBACK");

__ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_CLAUSE_ARG(ALSQLUpdateStatement, _qualifiedTableName, UPDATE);

__ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_WHERE   (ALSQLUpdateStatement, _where);
__ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_ORDER_BY(ALSQLUpdateStatement, _orderBy);
__ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_LIMIT   (ALSQLUpdateStatement, _limit);
__ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_OFFSET  (ALSQLUpdateStatement, _offset);


- (NSMutableArray<ALSQLClause *> *)setClauses {
    if (_setClauses == nil) {
        _setClauses = [NSMutableArray array];
    }
    return _setClauses;
}

- (void)setSetClauseWithDictionary:(NSDictionary *)dict {
    [dict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *sql = nil;
        if ([key isKindOfClass:NSString.class]) {
            sql = key;
        }
        if ([key isKindOfClass:NSArray.class]) {
            sql = [[(NSArray *)key bk_select:^BOOL(id tmpKey) {
                return al_stringValue(tmpKey) != nil;
            }] componentsJoinedByString:@", "];
            sql = [NSString stringWithFormat:@"(%@)", sql];
        }
        
        if (sql == nil) {
            return;
        }
        ALSQLClause *subSet = [sql al_SQLClause];
        
        if ([obj isKindOfClass:ALSQLClause.class]) {
            [subSet append:(ALSQLClause *)obj withDelimiter:@" = "];
        } else if (obj == NSNull.null) {
            [subSet appendSQLString:@"NULL" argValues:nil withDelimiter:@" = "];
        } else {
            [subSet appendSQLString:@"?" argValues:@[obj] withDelimiter:@" = "];
        }
        
        [[self setClauses] addObject:subSet];
    }];
}

- (ALSQLUpdateStatement *(^)(id clauses))SET {
    return ^ALSQLUpdateStatement *(id clause) {
        __ALSQLSTMT_BLOCK_CHAIN_OBJ_VERIFY();
        
        if ([clause isKindOfClass:NSDictionary.class]) {
            [self setSetClauseWithDictionary:clause];
        }
        else if ([clause isKindOfClass:ALSQLClause.class]) {
            [[self setClauses] addObject:clause];
        }
        else if ([clause isKindOfClass:NSArray.class]) {
            [clause enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj isKindOfClass:ALSQLClause.class]) {
                    [[self setClauses] addObject:obj];
                }
            }];
        }
        _needReBuild = YES;
        return self;
    };
}

- (nullable ALSQLClause *)SQLClause {
    __ALSQLSTMT_BUILD_SQL_VERIFY();
    
    ALSQLClause *sql = [@"UPDATE" al_SQLClause];
    
    if (!al_isEmptyString(_policy)) {
        [sql appendSQLString:_policy argValues:nil withDelimiter:@" "];
    }
    
    if ([_qualifiedTableName isValid]) {
        [sql append:_qualifiedTableName withDelimiter:@" "];
    } else {
        ALAssert(NO, @"*** 'qualified-table-name' must be specified !!!");
    }
    
    if (_setClauses.count > 0) {
        [sql appendSQLString:@" SET " argValues:nil withDelimiter:nil];
        __ALSQLSTMT_JOIN_CLAUSE_ARRAY(sql, _setClauses, @", ");
    } else {
        ALAssert(NO, @"*** 'set clause' must be specified!!!");
    }
    
    if ([_where isValid]) {
        [sql append:_where withDelimiter:@" WHERE "];
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

NS_ASSUME_NONNULL_END
