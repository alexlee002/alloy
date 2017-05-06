//
//  ALSQLInsertStatement.m
//  patchwork
//
//  Created by Alex Lee on 2/23/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALSQLInsertStatement.h"
#import "NSString+Helper.h"
#import "__ALSQLStatementHelpers.h"
#import "SafeBlocksChain.h"
#import "ALUtilitiesHeader.h"


@implementation ALSQLInsertStatement {
    BOOL                         _isReplce;
    NSString                    *_table;
    NSString                    *_policy;
    NSArray<NSString *>         *_columns;
    NSMutableArray<NSArray<ALSQLClause *> *> *_values;
    ALSQLClause                 *_selectStatement;
    BOOL        _usingDefaultValues;
    
    ALSQLClause *_SQLClause;
    BOOL         _needReBuild;
}


__ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_POLICY(ALSQLInsertStatement, OR_FAIL,     @"OR FAIL");
__ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_POLICY(ALSQLInsertStatement, OR_ABORT,    @"OR ABORT");
__ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_POLICY(ALSQLInsertStatement, OR_IGNORE,   @"OR IGNORE");
__ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_POLICY(ALSQLInsertStatement, OR_REPLACE,  @"OR REPLACE");
__ALSQLSTMT_BLOCK_PROP_SYNTHESIZE_POLICY(ALSQLInsertStatement, OR_ROLLBACK, @"OR ROLLBACK");


- (ALSQLInsertStatement *(^)())INSERT {
    return ^ALSQLInsertStatement *() {
        __ALSQLSTMT_BLOCK_CHAIN_OBJ_VERIFY();
        _isReplce = NO;
        return self;
    };
}

- (ALSQLInsertStatement *(^)())REPLACE {
    return ^ALSQLInsertStatement *() {
        __ALSQLSTMT_BLOCK_CHAIN_OBJ_VERIFY();
        _isReplce = YES;
        return self;
    };
}

- (ALSQLInsertStatement * (^)(NSString *table))INTO {
    return ^ALSQLInsertStatement *(NSString *table) {
        _table = [table copy];
        return self;
    };
}

- (void)addColumnValues:(NSArray<ALSQLClause *> *)values {
    if (values.count == 0) {
        return;
    }
    
    if (_values == nil) {
        _values = [NSMutableArray array];
    }
    [_values addObject:values];
}

- (ALSQLInsertStatement *(^)(NSDictionary<NSString *, id> *values))VALUES_DICT {
    return ^ALSQLInsertStatement *(NSDictionary<NSString *, id> *values) {
        __ALSQLSTMT_BLOCK_CHAIN_OBJ_VERIFY();
        
        NSInteger count = values.count;
        if (count == 0) {
            _columns = nil;
            _values  = nil;
        } else {
            NSMutableArray<NSString *>    *keys = [NSMutableArray arrayWithCapacity:count];
            NSMutableArray<ALSQLClause *> *objs = [NSMutableArray arrayWithCapacity:count];
            [values enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                id val = obj;
                if (![obj isKindOfClass:ALSQLClause.class]) {
                    val = [obj al_SQLClauseByUsingAsArgValue];
                }
                if (val != nil) {
                    [keys addObject:key];
                    [objs addObject:val];
                } else {
                    ALAssert(NO, @"*** Invalid column value: {%@: %@}", key, obj);
                }
            }];
            
            ALAssert(keys.count == objs.count, @"*** columns not matches with values");
            _columns = keys;
            [self addColumnValues:objs];
        }
        _selectStatement = nil;
        _usingDefaultValues = NO;
        _needReBuild = YES;
        return self;
    };
}

- (ALSQLInsertStatement *(^)(NSArray<NSString *> *cols))COLUMNS {
    return ^ALSQLInsertStatement *(NSArray<NSString *> *cols) {
        __ALSQLSTMT_BLOCK_CHAIN_OBJ_VERIFY();
        _columns = [cols copy];
        _needReBuild = YES;
        return self;
    };
}

- (ALSQLInsertStatement *(^)(NSArray *values))VALUES {
    return ^ALSQLInsertStatement *(NSArray *values) {
        __ALSQLSTMT_BLOCK_CHAIN_OBJ_VERIFY();
        if (values.count > 0) {
            NSMutableArray<ALSQLClause *> *clauses = [NSMutableArray arrayWithCapacity:values.count];
            for (id val in values) {
                if ([val isKindOfClass:ALSQLClause.class]) {
                    [clauses addObject:(ALSQLClause *)val];
                } else {
                    id tmpVal = [val al_SQLClauseByUsingAsArgValue];
                    if (tmpVal != nil) {
                        [clauses addObject:tmpVal];
                    } else {
                        ALAssert(NO, @"*** invalid column value: %@", val);
                    }
                }
            }

            [self addColumnValues:clauses];
            _usingDefaultValues = NO;
        }
        _needReBuild = YES;
        return self;
    };
}

- (ALSQLInsertStatement *(^)())DEFAULT_VALUES {
    return ^ALSQLInsertStatement *() {
        __ALSQLSTMT_BLOCK_CHAIN_OBJ_VERIFY();
        _usingDefaultValues = YES;
        _needReBuild = YES;
        return self;
    };
}

- (ALSQLInsertStatement *(^)(ALSQLClause *selectStmt))SELECT_STMT {
    return ^ALSQLInsertStatement *(ALSQLClause *stmt) {
        __ALSQLSTMT_BLOCK_CHAIN_OBJ_VERIFY();
        _selectStatement = [stmt copy];
        _usingDefaultValues = NO;
        _needReBuild = YES;
        return self;
    };
}


- (nullable ALSQLClause *)SQLClause {
    __ALSQLSTMT_BUILD_SQL_VERIFY();
    
    ALSQLClause *sql = [(_isReplce ? @"REPLACE" : @"INSERT") al_SQLClause];
    
    if (!_isReplce && !al_isEmptyString(_policy)) {
        [sql appendSQLString:_policy argValues:nil withDelimiter:@" "];
    }
    
    if (!al_isEmptyString(_table)) {
        [sql appendSQLString:_table argValues:nil withDelimiter:@" INTO "];
    } else {
        ALAssert(NO, @"*** 'table-name' must be specified !!!");
    }
    
    if (_columns.count > 0) {
        [sql appendSQLString:[NSString stringWithFormat:@"(%@)", [_columns componentsJoinedByString:@", "]]
          argValues:nil
      withDelimiter:@" "];
    }
    
    if (_values.count > 0) {
        [sql appendSQLString:@" VALUES " argValues:nil withDelimiter:nil];
        [_values enumerateObjectsUsingBlock:^(NSArray<ALSQLClause *> * _Nonnull rowValues, NSUInteger idx, BOOL * _Nonnull stop) {
            if (idx > 0) {
                [sql appendSQLString:@", " argValues:nil withDelimiter:nil];
            }
            
            [sql appendSQLString:@"(" argValues:nil withDelimiter:nil];
            __ALSQLSTMT_JOIN_CLAUSE_ARRAY(sql, rowValues, @", ");
            [sql appendSQLString:@")" argValues:nil withDelimiter:nil];
        }];
    } else if ([_selectStatement isValid]) {
        [sql append:_selectStatement withDelimiter:@" "];
    } else if (_usingDefaultValues) {
        [sql appendSQLString:@" DEFAULT VALUES" argValues:nil withDelimiter:nil];
    }
    
    _SQLClause = sql;
    _needReBuild = NO;
    
    return _SQLClause;
}

@end
