//
//  ALSQLClause+SQLFunctions.m
//  patchwork
//
//  Created by Alex Lee on 2016/10/18.
//  Copyright © 2016年 Alex Lee. All rights reserved.
//

#import "ALSQLClause+SQLFunctions.h"
#import "NSString+Helper.h"

FORCE_INLINE ALSQLClause *sql_func1(NSString *funcName, NSArray *args) {
    NSMutableString *sql = [funcName.uppercaseString mutableCopy];
    NSMutableArray *sqlArgs = [NSMutableArray array];
    [sql appendString:@"("];
    
    [args enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx > 0) {
            [sql appendString:@", "];
        }
        
        if ([obj isKindOfClass:[ALSQLClause class]]) {
            [sql appendString:((ALSQLClause *)obj).SQLString];
            [sqlArgs addObjectsFromArray:((ALSQLClause *)obj).argValues];
        } else if ([obj isKindOfClass:[NSString class]]) {
            [sql appendString:(NSString *)obj];
        } else if ([obj isKindOfClass:[NSNumber class]]) {
            [sql appendString:((NSNumber *)obj).stringValue];
        } else if ([obj respondsToSelector:@selector(stringValue)]) {
            [sql appendString:[obj stringValue]];
        }
    }];
    
    [sql appendString:@")"];
    
    return [sql toSQLWithArgValues:(sqlArgs.count > 0 ? sqlArgs : nil)];
}

FORCE_INLINE ALSQLClause *NS_REQUIRES_NIL_TERMINATION sqlFunc(NSString *funcName, id arg, ...) {
    
    NSMutableArray *args = [NSMutableArray array];
    va_list valist;
    va_start(valist, arg);
    id a = arg;
    while (a != nil) {
        [args addObject:a];
        a = va_arg(valist, id);
    }
    va_end(valist);
    
    return sql_func1(funcName, args);
}


FORCE_INLINE ALSQLClause *SQL_LENGTH(id obj) {
    return sqlFunc(@"LENGTH", obj, nil);
}

FORCE_INLINE ALSQLClause *SQL_ABS(id obj) {
    return sqlFunc(@"ABS", obj, nil);
}

FORCE_INLINE ALSQLClause *SQL_LOWER(id obj) {
    return sqlFunc(@"LOWER", obj, nil);
}

FORCE_INLINE ALSQLClause *SQL_UPPER(id obj) {
    return sqlFunc(@"UPPER", obj, nil);
}

FORCE_INLINE ALSQLClause *SQL_MAX(id objs) {
    
    if (![objs isKindOfClass:NSArray.class]) {
        return sqlFunc(@"MAX", objs, nil);
    } else {
        return sql_func1(@"MAX", objs);
    }
}

FORCE_INLINE ALSQLClause *SQL_MIN(id objs) {
    if (![objs isKindOfClass:NSArray.class]) {
        return sqlFunc(@"MIN", objs, nil);
    } else {
        return sql_func1(@"MIN", objs);
    }
}

FORCE_INLINE ALSQLClause *SQL_REPLACE(id src, id target, id replacement) {
    return sqlFunc(@"REPLACE", target, replacement, nil);
}

FORCE_INLINE ALSQLClause *SQL_SUBSTR(id src, NSInteger from, NSInteger len) {
    return sqlFunc(@"SUBSTR", @(from), @(len), nil);
}

FORCE_INLINE ALSQLClause *SQL_COUNT(id _Nullable obj) {
    return sqlFunc(@"COUNT", obj ?: @"*", nil);
}

FORCE_INLINE ALSQLClause *SQL_SUM(id obj) {
    return sqlFunc(@"SUM", obj, nil);
}

FORCE_INLINE ALSQLClause *SQL_AVG(id obj) {
    return sqlFunc(@"AVG", obj, nil);
}

//@implementation ALSQLClause (SQLFunctions)
//
//@end
