//
//  ALSQLClause+SQLFunctions.m
//  patchwork
//
//  Created by Alex Lee on 2016/10/18.
//  Copyright © 2016年 Alex Lee. All rights reserved.
//

#import "ALSQLClause+SQLFunctions.h"
#import "NSString+Helper.h"
#import "ALUtilitiesHeader.h"

AL_FORCE_INLINE ALSQLClause *SQLFunc(NSString *funcName, NSArray *args) {
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
        } else {
            [sql appendString:(al_stringValue(obj) ?: @"")];
        }
    }];
    
    [sql appendString:@")"];
    
    return [sql al_SQLClauseWithArgValues:(sqlArgs.count > 0 ? sqlArgs : nil)];
}

AL_FORCE_INLINE ALSQLClause *SQL_LENGTH(id obj) {
    return SQLFunc(@"LENGTH", @[ al_wrapNil(obj) ]);
}

AL_FORCE_INLINE ALSQLClause *SQL_ABS(id obj) {
    return SQLFunc(@"ABS", @[ al_wrapNil(obj) ]);
}

AL_FORCE_INLINE ALSQLClause *SQL_LOWER(id obj) {
    return SQLFunc(@"LOWER", @[ al_wrapNil(obj) ]);
}

AL_FORCE_INLINE ALSQLClause *SQL_UPPER(id obj) {
    return SQLFunc(@"UPPER", @[ al_wrapNil(obj) ]);
}

AL_FORCE_INLINE ALSQLClause *SQL_MAX(id objs) {
    
    if (![objs isKindOfClass:NSArray.class]) {
        return SQLFunc(@"MAX", @[ al_wrapNil(objs) ]);
    } else {
        return SQLFunc(@"MAX", al_wrapNil(objs));
    }
}

AL_FORCE_INLINE ALSQLClause *SQL_MIN(id objs) {
    if (![objs isKindOfClass:NSArray.class]) {
        return SQLFunc(@"MIN", @[ al_wrapNil(objs) ]);
    } else {
        return SQLFunc(@"MIN", al_wrapNil(objs));
    }
}

AL_FORCE_INLINE ALSQLClause *SQL_REPLACE(id src, id target, id replacement) {
    return SQLFunc(@"REPLACE", @[ al_wrapNil(target), al_wrapNil(replacement) ]);
}

AL_FORCE_INLINE ALSQLClause *SQL_SUBSTR(id src, NSInteger from, NSInteger len) {
    return SQLFunc(@"SUBSTR", @[ @(from), @(len) ]);
}

AL_FORCE_INLINE ALSQLClause *SQL_COUNT(id _Nullable obj) {
    return SQLFunc(@"COUNT", @[obj ?: @"*"]);
}

AL_FORCE_INLINE ALSQLClause *SQL_SUM(id obj) {
    return SQLFunc(@"SUM", @[ al_wrapNil(obj) ]);
}

AL_FORCE_INLINE ALSQLClause *SQL_AVG(id obj) {
    return SQLFunc(@"AVG", @[ al_wrapNil(obj) ]);
}

