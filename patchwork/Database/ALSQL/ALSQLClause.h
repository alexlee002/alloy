//
//  ALSQLClause.h
//  patchwork
//
//  Created by Alex Lee on 16/10/12.
//  Copyright © 2016年 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALUtilitiesHeader.h"

NS_ASSUME_NONNULL_BEGIN

@interface ALSQLClause : NSObject <NSCopying>

@property(PROP_ATOMIC_DEF, copy, nullable, readonly) NSString  *SQLString;
@property(PROP_ATOMIC_DEF, copy, nullable)           NSArray   *argValues;

+ (instancetype)SQLClauseWithString:(NSString *)sql, ...NS_REQUIRES_NIL_TERMINATION;
+ (instancetype)SQLClauseWithString:(NSString *)sql argValues:(NSArray *_Nullable)argValues;

- (BOOL)isValid;

@end

// chain syntax support
@interface ALSQLClause (ALBlocksChain)
@property(readonly) ALSQLClause *(^APPEND)(id obj, NSString *_Nullable delimiter);
@property(readonly) ALSQLClause *(^SET_ARG_VALUES)(NSArray * _Nullable values);
@end

@interface ALSQLClause (BaseOperations)
- (void)append:(ALSQLClause *)other withDelimiter:(NSString *_Nullable)delimiter;
- (void)appendSQLString:(NSString *)sql
              argValues:(NSArray *_Nullable)argValues
          withDelimiter:(NSString *_Nullable)delimiter;
- (void)appendAfterSQLString:(NSString *)sql withDelimiter:(NSString *_Nullable)delimiter;
@end

@interface NSString (ALSQLClause)
- (ALSQLClause *)al_SQLClauseWithArgValues:(NSArray *)argValues;
- (ALSQLClause *)al_SQLClauseByAppendingSQLClause:(ALSQLClause *)sql withDelimiter:(NSString *_Nullable)delimiter;
- (ALSQLClause *)al_SQLClauseByAppendingSQL:(NSString *)sql argValues:(NSArray *)argValues delimiter:(NSString *_Nullable)delimiter;

@end

@interface NSObject (ALSQLClause)
- (ALSQLClause *_Nullable)al_SQLClause;

//eg: [@1 al_SQLClauseByUsingAsArgValue] => sql: ?; arg: 1
- (ALSQLClause *_Nullable)al_SQLClauseByUsingAsArgValue;
- (BOOL)al_isAcceptableSQLArgClassType;
@end

NS_ASSUME_NONNULL_END
