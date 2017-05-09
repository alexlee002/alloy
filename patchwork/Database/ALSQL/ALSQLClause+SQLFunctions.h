//
//  ALSQLClause+SQLFunctions.h
//  patchwork
//
//  Created by Alex Lee on 2016/10/18.
//  Copyright © 2016年 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALSQLClause.h"

NS_ASSUME_NONNULL_BEGIN

extern ALSQLClause *SQLFunc(NSString *funcName, NSArray *args);

extern ALSQLClause *SQL_LENGTH  (id obj);
extern ALSQLClause *SQL_ABS     (id obj);
extern ALSQLClause *SQL_LOWER   (id obj);
extern ALSQLClause *SQL_UPPER   (id obj);

// objs: NSString, ALSQLClause, NSArray
extern ALSQLClause *SQL_MAX     (id objs);
extern ALSQLClause *SQL_MIN     (id objs);

extern ALSQLClause *SQL_REPLACE (id src, id target, id replacement);
extern ALSQLClause *SQL_SUBSTR  (id src, NSInteger from, NSInteger len);
extern ALSQLClause *SQL_COUNT   (id _Nullable obj);
extern ALSQLClause *SQL_SUM     (id obj);
extern ALSQLClause *SQL_AVG     (id obj);

extern ALSQLClause *SQL_NOT     (id obj);

NS_ASSUME_NONNULL_END
