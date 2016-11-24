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

@interface ALSQLClause : NSObject <NSCopying>

@property(PROP_ATOMIC_DEF, copy, readonly, nullable) NSString *SQLString;
@property(PROP_ATOMIC_DEF, copy, nullable)           NSArray  *argValues;

+ (instancetype)SQLClauseWithString:(NSString *)sql, ...NS_REQUIRES_NIL_TERMINATION;
+ (instancetype)SQLClauseWithString:(NSString *)sql argValues:(NSArray *_Nullable)argValues;

- (void)appendArgValues:(NSArray *)argValues;
- (BOOL)isValid;

@end

// chain syntax support
@interface ALSQLClause (ALBlocksChain)
@property(readonly) ALSQLClause *(^APPEND)(ALSQLClause *other, NSString *_Nullable delimiter);
@property(readonly) ALSQLClause *(^SET_ARG_VALUES)(NSArray * _Nullable values);
@property(readonly) ALSQLClause *(^ADD_ARG_VALUES)(NSArray *values);
@end


@interface ALSQLClause (BaseOperations)
- (void)append:(ALSQLClause *)other withDelimiter:(NSString *_Nullable)delimiter;
- (void)append:(NSString *)sql argValues:(NSArray *_Nullable)argValues withDelimiter:(NSString *_Nullable)delimiter;
@end


@interface NSString (ALSQLClause)

- (ALSQLClause *)SQLClauseWithArgValues:(NSArray *)argValues;

@end

@interface NSObject (ALSQLClause)
- (ALSQLClause *_Nullable)SQLClause;
- (ALSQLClause *_Nullable)SQLClauseArgValue;
@end

NS_ASSUME_NONNULL_END
