//
//  ALSQLCondition.h
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UtilitiesHeader.h"
#import "ALSQLExpression.h"

NS_ASSUME_NONNULL_BEGIN

@class ALSQLCondition;

// mark 'exp' is an expression, not value
extern ALSQLExpression *AS_EXP(id exp);

// expression should by NSString or ALSQLExpression
extern ALSQLCondition *EQ   (id expression, id value);
extern ALSQLCondition *LT   (id expression, id value);
extern ALSQLCondition *GT   (id expression, id value);
extern ALSQLCondition *NLT  (id expression, id value);
extern ALSQLCondition *NGT  (id expression, id value);
extern ALSQLCondition *NEQ  (id expression, id value);
extern ALSQLCondition *IS_NULL    (id expression);
extern ALSQLCondition *IS_NOT_NULL(id expression);
extern ALSQLCondition *NOT        (id expression);

extern ALSQLCondition *IN(id expression, NSArray *values);

// 'LIKE' pattern,
// matchsAny:           using "%"
// natural number(>0):  using "_"
extern const NSUInteger matchsAny;
extern ALSQLCondition *LIKE(id expression, NSString *likeExpression);
// eg: LIKE '%abc'
extern ALSQLCondition *MATCHS_SUBFIX(id expression, id arg, NSUInteger matchs);
// eg: LIKE 'abc%'
extern ALSQLCondition *MATCHS_PREFIX(id expression, id arg, NSUInteger matchs);

// condition should be Array of ALSQLCondition or ALSQLExpression
extern ALSQLCondition *AND(NSArray *conditions);
extern ALSQLCondition *OR(NSArray *conditions);

typedef NS_ENUM(NSInteger, DBValueType) {
    DBValueTypeNormal       = 0,
    DBValueTypeColumnName   = 1
};

/**
 *  condition block
 *
 *  @param cond should be kind of ALSQLCondition or ALSQLExpression
 *
 *  @return ALSQLCondition
 */
typedef ALSQLCondition *_Nullable (^ALSQLConditionBlock)(id condition);
typedef ALSQLCondition *_Nullable (^ALSQLConditionLikeBlock)(id condition, NSUInteger matches);

@interface ALSQLCondition : NSObject

@property(readonly) NSString *sqlClause;
@property(readonly) NSArray  *sqlArguments;

@property(readonly) ALSQLConditionBlock AND;
@property(readonly) ALSQLConditionBlock OR;

+ (instancetype)conditionWithString:(NSString *)string args:(nullable id)arg, ... NS_REQUIRES_NIL_TERMINATION;
- (instancetype)initWithString:(NSString *)string args:(nullable id)arg, ... NS_REQUIRES_NIL_TERMINATION;

- (instancetype)build;

@end

@interface NSString (ALSQLCondition)
- (ALSQLCondition *)SQLCondition;
@end

@interface ALSQLExpression (ALSQLCondition)
- (ALSQLCondition *)SQLCondition;
@end


@interface NSObject (ALSQLCondition)

@property(readonly) ALSQLConditionBlock EQ;
@property(readonly) ALSQLConditionBlock LT;
@property(readonly) ALSQLConditionBlock GT;
@property(readonly) ALSQLConditionBlock NLT;
@property(readonly) ALSQLConditionBlock NGT;
@property(readonly) ALSQLConditionBlock NEQ;
@property(readonly) ALSQLConditionBlock IN;
@property(readonly) ALSQLConditionBlock LIKE;
@property(readonly) ALSQLConditionLikeBlock MATCHS_SUBFIX;
@property(readonly) ALSQLConditionLikeBlock MATCHS_PREFIX;

@end


NS_ASSUME_NONNULL_END
