//
//  ALDBStatement.m
//  alloy
//
//  Created by Alex Lee on 02/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDBStatement.h"
#import "ALDBStatement_Private.h"
#import "ALDBResultSet_Private.h"
#import "NSObject+SQLValue.h"
#import "NSError+ALDBError.h"
#import "ALMacros.h"
#import "sql_value.hpp"
#import "NSObject+SQLValue.h"

@implementation ALDBStatement {
    BOOL _needResetBindings;
}

- (instancetype)initWithCoreStatementHandle:(aldb::RecyclableStatement &)coreStmtHandle
                               SQLStatement:(const std::shared_ptr<aldb::SQLStatement>)sqlstmt{
    if (!coreStmtHandle) {
        return nil;
    }
    
    self = [self init];
    if (self) {
        _coreStmtHandle = coreStmtHandle;
        _sqlStmt = sqlstmt;
    }
    return self;
}

- (BOOL)hasError {
    al_guard_or_return(_coreStmtHandle, NO);
    return _coreStmtHandle->has_error();
}

- (NSError *)lastError {
    al_guard_or_return(_coreStmtHandle, nil);
    auto err = _coreStmtHandle->get_error();
    if (err) {
        return [NSError errorWithALDBError: *err];
    }
    return nil;
}

- (BOOL)exec {
    al_guard_or_return(_coreStmtHandle, NO);
    if (!_sqlStmt) {
        return NO;
    }
    return [self exec:_sqlStmt->values()];
}
- (nullable ALDBResultSet *)query {
    al_guard_or_return(_coreStmtHandle, nil);
    if (!_sqlStmt) {
        return nil;
    }
    return [self query:_sqlStmt->values()];
}

- (BOOL)execWithValues:(nullable NSArray *)values; {
    al_guard_or_return(_coreStmtHandle, NO);
    
    if (_needResetBindings) {
        [self resetBindings];
    }
    NSInteger index = 1;
    for (id value in values) {
        if(![self bindObject:value atIndex:index]) {
            return NO;
        }
        ++index;
    }
    _needResetBindings = YES;
    return _coreStmtHandle->exec();
}

- (ALDBResultSet *)queryWithValues:(nullable NSArray *)values; {
    al_guard_or_return(_coreStmtHandle, nil);
    
    if (_needResetBindings) {
        [self resetBindings];
    }
    
    NSInteger index = 1;
    for (id value in values) {
        if(![self bindObject:value atIndex:index]) {
            return nil;
        }
        ++index;
    }
    _needResetBindings = YES;
    return [[ALDBResultSet alloc] initWithCoreStatementHandle:_coreStmtHandle SQLStatement:_sqlStmt];
}

- (NSInteger)lastInsertRowId {
    al_guard_or_return(_coreStmtHandle, 0);
    return _coreStmtHandle->last_insert_rowid();
}

- (NSInteger)changes {
    al_guard_or_return(_coreStmtHandle, 0);
    return _coreStmtHandle->changes();
}

- (BOOL)resetBindings {
    al_guard_or_return(_coreStmtHandle, NO);
    return _coreStmtHandle->reset_bindings();
}

- (BOOL)bindObject:(id)value atIndex:(NSInteger)index {
    al_guard_or_return(_coreStmtHandle, NO);
    return _coreStmtHandle->bind_value([value al_SQLValue], (int)index);
}

- (NSString *)sql {
    const char *sql = _coreStmtHandle->sql();
    return sql ? @(sql) : nil;
}
- (NSString *)expandedSQL {
    const char *sql = _coreStmtHandle->expanded_sql();
    return sql ? @(sql) : nil;
}

@end


#ifdef __cplusplus
@implementation ALDBStatement (CXX_Interface)
- (bool)bindValue:(const aldb::SQLValue &)value atIndex:(int)index {
    al_guard_or_return(_coreStmtHandle, false);
    return _coreStmtHandle->bind_value(value, (int)index);
}

- (bool)exec:(const std::list<const aldb::SQLValue> &)values {
    al_guard_or_return(_coreStmtHandle, false);
    
    if (_needResetBindings) {
        [self resetBindings];
    }
    int index = 1;
    for (auto value : values) {
        if(![self bindValue:value atIndex:index]) {
            return false;
        }
        ++index;
    }
    _needResetBindings = YES;
    return _coreStmtHandle->exec();
}

- (nullable ALDBResultSet *)query:(const std::list<const aldb::SQLValue> &)values {
    al_guard_or_return(_coreStmtHandle, nil);
    
    if (_needResetBindings) {
        [self resetBindings];
    }
    int index = 1;
    for (auto value : values) {
        if(![self bindValue:value atIndex:index]) {
            return nil;
        }
        ++index;
    }
    _needResetBindings = YES;
    return [[ALDBResultSet alloc] initWithCoreStatementHandle:_coreStmtHandle SQLStatement:_sqlStmt];
}
@end
#endif
