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

extern ALSQLClause *NS_REQUIRES_NIL_TERMINATION sqlFunc(NSString *funcName, id arg, ...);

extern ALSQLClause *SQL_LENGTH  (id obj);
extern ALSQLClause *SQL_ABS     (id obj);
extern ALSQLClause *SQL_LOWER   (id obj);
extern ALSQLClause *SQL_UPPER   (id obj);
extern ALSQLClause *SQL_MAX     (NSArray *objs);
extern ALSQLClause *SQL_MIN     (NSArray *objs);
extern ALSQLClause *SQL_REPLACE (id src, id target, id replacement);
extern ALSQLClause *SQL_SUBSTR  (id src, NSInteger from, NSInteger len);


//@interface ALSQLClause (SQLFunctions)
//
//@end

NS_ASSUME_NONNULL_END
