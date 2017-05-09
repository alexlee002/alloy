//
//  ALSQLStatementHelpers.h
//  patchwork
//
//  Created by Alex Lee on 2016/10/21.
//  Copyright © 2016年 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "__patchwork_config.h"
#import "ALLogger.h"
#import "ALUtilitiesHeader.h"

// private utilities tools for ALSQLStatment

#ifndef __ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_POLICY
#define __ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_POLICY(stmt_class, prop_name, policy)   \
- (stmt_class * (^)(BOOL yesOrNo))prop_name {               \
    return ^stmt_class *(BOOL yesOrNo) {                    \
        __ALSQLSTMT_BLOCK_CHAIN_OBJ_VERIFY();               \
        _policy = yesOrNo ? policy : nil;                   \
        _needReBuild = YES;                                 \
        return self;                                        \
    };                                                      \
}
#endif

// getter template for SQL Statement'block property with NSString / ALSQLClause argument
#ifndef __ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_CLAUSE_ARG
#define __ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_CLAUSE_ARG(stmt_class, _ivar_name, prop_name) \
- (stmt_class *(^)(id clause))prop_name {                   \
    return ^stmt_class *(id clause) {                       \
        __ALSQLSTMT_BLOCK_CHAIN_OBJ_VERIFY();               \
        _ivar_name = ([clause isKindOfClass:ALSQLClause.class]) ? [clause copy] : [clause al_SQLClause];   \
        _needReBuild = YES;                                 \
        return self;                                        \
    };                                                      \
}
#endif

// 'FROM' getter template
#ifndef __ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_FROM
#define __ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_FROM(stmt_class, _from_var)   \
        __ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_CLAUSE_ARG(stmt_class, _from_var, FROM)
#endif

// 'HAVING' getter template
#ifndef __ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_HAVING
#define __ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_HAVING(stmt_class, _from_var)   \
__ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_CLAUSE_ARG(stmt_class, _from_var, HAVING)
#endif

// 'WHERE' getter template
#ifndef __ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_WHERE
#define __ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_WHERE(stmt_class, _where_var)   \
- (stmt_class *(^)(id clause))WHERE {                           \
    return ^stmt_class *(id clause) {                           \
        __ALSQLSTMT_BLOCK_CHAIN_OBJ_VERIFY();                   \
        ALSQLClause *__tmpWhere = nil;                          \
        if ([clause isKindOfClass:ALSQLClause.class]) {         \
            __tmpWhere = [(ALSQLClause *)clause copy];          \
        } else {                                                \
            __tmpWhere = [clause al_SQLClause];                    \
        }                                                       \
        if (__tmpWhere != nil) {                                \
            if (_where_var == nil) {                            \
                _where_var = __tmpWhere;                        \
            } else {                                            \
                _where_var.SQL_AND(__tmpWhere);                 \
            }                                                   \
        }                                                       \
        _needReBuild = YES;                                     \
        return self;                                            \
    };                                                          \
}
#endif

// using by 'order by' or  'group by'
#ifndef __APPEND_ORDER_BY_CLAUSE
#define __APPEND_ORDER_BY_CLAUSE(_ivar_name, expr_clause)     \
if ([expr_clause isKindOfClass:ALSQLClause.class]) {          \
    ALSQLClause *other = (ALSQLClause *)expr_clause;          \
    _ivar_name == nil ? (_ivar_name = [other copy]) : [_ivar_name append:other withDelimiter:@", "];            \
} else if ([expr_clause isKindOfClass:NSString.class]) {                                                        \
    _ivar_name == nil ? (_ivar_name = [expr_clause al_SQLClause])                                               \
                      : [_ivar_name appendSQLString:(NSString *)expr_clause argValues:nil withDelimiter:@", "]; \
}
#endif

#ifndef __ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_ORDER_GROUP_BY
#define __ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_ORDER_GROUP_BY(stmt_class, _ivar_name, prop_name) \
- (stmt_class *(^)(id exprs))prop_name {                            \
    return ^stmt_class *(id exprs) {                                \
        __ALSQLSTMT_BLOCK_CHAIN_OBJ_VERIFY();                       \
        __APPEND_ORDER_BY_CLAUSE(_ivar_name, exprs)                 \
        else if ([exprs isKindOfClass:NSArray.class]) {             \
            for (ALSQLClause *tmpExp in exprs) {                    \
                __APPEND_ORDER_BY_CLAUSE(_ivar_name, tmpExp)        \
            }                                                       \
        }                                                           \
        _needReBuild = YES;                                         \
        return self;                                                \
    };                                                              \
}
#endif

// 'ORDER_BY' getter template
#ifndef __ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_ORDER_BY
#define __ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_ORDER_BY(stmt_class, _order_by_ivar)  \
    __ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_ORDER_GROUP_BY(stmt_class, _order_by_ivar, ORDER_BY)
#endif

// 'GROUP_BY' getter template
#ifndef __ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_GROUP_BY
#define __ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_GROUP_BY(stmt_class, _order_by_ivar)  \
__ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_ORDER_GROUP_BY(stmt_class, _order_by_ivar, GROUP_BY)
#endif

// 'OFFSET' getter template
#ifndef __ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_OFFSET
#define __ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_OFFSET(stmt_class, _offset_var)   \
- (stmt_class *(^)(id expr))OFFSET {                            \
    return ^stmt_class *(id expr) {                             \
        __ALSQLSTMT_BLOCK_CHAIN_OBJ_VERIFY();                   \
        _offset_var = [expr isKindOfClass:ALSQLClause.class] ? [((ALSQLClause *)expr) copy] : [expr al_SQLClause]; \
        _needReBuild = YES;                                     \
        return self;                                            \
    };                                                          \
}
#endif

// 'LIMIT' getter template
#ifndef __ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_LIMIT
#define __ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_LIMIT(stmt_class, _limit_var)     \
- (stmt_class *(^)(id expr))LIMIT {     \
    return ^stmt_class *(id expr) {     \
        __ALSQLSTMT_BLOCK_CHAIN_OBJ_VERIFY();   \
        _limit_var = [expr isKindOfClass:ALSQLClause.class] ? [((ALSQLClause *)expr) copy] : [expr al_SQLClause];  \
        _needReBuild = YES;             \
        return self;                    \
    };                                  \
}
#endif


// safe blocks chain
#ifndef __ALSQLSTMT_BLOCK_CHAIN_OBJ_VERIFY
#define __ALSQLSTMT_BLOCK_CHAIN_OBJ_VERIFY() al_isValidBlocksChainObjectOrReturn(self, self)

#endif

// using in sqlstatment's SQLClause
#ifndef __ALSQLSTMT_BUILD_SQL_VERIFY
#define __ALSQLSTMT_BUILD_SQL_VERIFY()          \
    if (![self al_isValidBlocksChainObject]) {     \
        ALLogError(@"%@", (self));              \
        return nil;                             \
    }                                           \
                                                \
    if (!_needReBuild && _SQLClause != nil) {   \
        return _SQLClause;                      \
    }
#endif

//
#ifndef __ALSQLSTMT_JOIN_CLAUSE_ARRAY
#define __ALSQLSTMT_JOIN_CLAUSE_ARRAY(src, clause_array, delimiter)     \
[(clause_array) enumerateObjectsUsingBlock:^(ALSQLClause * _Nonnull _innerEnumObj, NSUInteger _innerEnmuIdx, BOOL * _Nonnull _stop) {   \
    if (_innerEnmuIdx > 0) {                                            \
        [(src) appendSQLString:(delimiter) argValues:nil withDelimiter:nil];     \
    }                                                                   \
    [(src) append:_innerEnumObj withDelimiter:nil];                     \
}];
#endif
