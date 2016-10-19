//
//  ALSQLClause+SQLOperation.h
//  patchwork
//
//  Created by Alex Lee on 16/10/13.
//  Copyright © 2016年 Alex Lee. All rights reserved.
//

#import "ALSQLClause.h"

typedef NS_ENUM(NSInteger, ALOperatorPos) {
    ALOperatorPosLeft = 1,
    ALOperatorPosMid,
    ALOperatorPosRight
};

NS_ASSUME_NONNULL_BEGIN

@interface ALSQLClause (SQLOperation)

- (void)operation:(NSString *)operatorName position:(ALOperatorPos)pos otherClause:(ALSQLClause *_Nullable)other;

@end

@interface NSObject (SQLOperation)

@property(readonly, copy) ALSQLClause *(^AND)(id obj);
@property(readonly, copy) ALSQLClause *(^OR) (id obj);
@property(readonly, copy) ALSQLClause *(^EQ) (id obj);
@property(readonly, copy) ALSQLClause *(^LT) (id obj);
@property(readonly, copy) ALSQLClause *(^GT) (id obj);
@property(readonly, copy) ALSQLClause *(^IN) (id obj);
@property(readonly, copy) ALSQLClause *(^LIKE)(id obj);

@property(readonly, copy) ALSQLClause *(^NOT)();
@property(readonly, copy) ALSQLClause *(^NLT)(id obj);
@property(readonly, copy) ALSQLClause *(^NEQ)(id obj);
@property(readonly, copy) ALSQLClause *(^NGT)(id obj);

@property(readonly, copy) ALSQLClause *(^IS_NULL)();
@property(readonly, copy) ALSQLClause *(^IS_NOT_NULL)();

@property(readonly, copy) ALSQLClause *(^HAS_PREFIX)(id obj);
@property(readonly, copy) ALSQLClause *(^HAS_SUBFIX)(id obj);

// CASE a WHEN b THEN c ELSE d END
@property(readonly, copy) ALSQLClause *(^CASE)(id _Nullable obj);
@property(readonly, copy) ALSQLClause *(^WHEN)(id obj);
@property(readonly, copy) ALSQLClause *(^THEN)(id obj);
@property(readonly, copy) ALSQLClause *(^ELSE)(id obj);
@property(readonly, copy) ALSQLClause *(^END)();

@end

NS_ASSUME_NONNULL_END
