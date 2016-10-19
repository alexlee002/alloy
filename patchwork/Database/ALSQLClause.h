//
//  ALSQLClause.h
//  patchwork
//
//  Created by Alex Lee on 16/10/12.
//  Copyright © 2016年 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UtilitiesHeader.h"

NS_ASSUME_NONNULL_BEGIN

@interface ALSQLClause : NSObject

@property(PROP_ATOMIC_DEF, copy, readonly, nullable) NSString *SQLString;
@property(PROP_ATOMIC_DEF, copy, readonly, nullable) NSArray  *argValues;

+ (instancetype)SQLClauseWithString:(NSString *)sql, ...NS_REQUIRES_NIL_TERMINATION;
+ (instancetype)SQLClauseWithString:(NSString *)sql argValuess:(NSArray *_Nullable)argValues;

- (void)setArgValues:(NSArray * _Nullable)argValues;
- (void)appendArgValues:(NSArray *)argValues;

- (void)append:(ALSQLClause *)other withSpace:(BOOL)withSpace;
- (void)append:(NSString *)sql argValues:(NSArray *)argValues withSpace:(BOOL)withSpace;

- (BOOL)isValid;

@end

// chain syntax support
@interface ALSQLClause (ALBlocksChain)
@property(readonly) ALSQLClause *(^APPEND)(ALSQLClause *other, BOOL withSpace);
@property(readonly) ALSQLClause *(^SET_ARG_VALUES)(NSArray * _Nullable values);
@property(readonly) ALSQLClause *(^ADD_ARG_VALUES)(NSArray *values);
@end

@interface NSString (ALSQLClause)

- (ALSQLClause *)toSQLWithArgValues:(NSArray *)argValues;

@end

@interface NSObject (ALSQLClause)
- (ALSQLClause *_Nullable)toSQL;
- (ALSQLClause *_Nullable)SQLFromArgValue;
@end

NS_ASSUME_NONNULL_END
