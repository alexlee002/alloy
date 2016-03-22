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

extern ALSQLExpression *OP_EXP  (id exp1, NSString *operator, id exp2);
extern ALSQLExpression *BIT_AND (id expression, id value);
extern ALSQLExpression *BIT_OR  (id expression, id value);
extern ALSQLExpression *BIT_XOR (id expression, id value);
extern ALSQLExpression *BIT_NOT (id expression, id value);

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
extern ALSQLCondition *LEFT_LIKE(id expression, id arg, NSUInteger matchs);
// eg: LIKE 'abc%'
extern ALSQLCondition *RIGHT_LIKE(id expression, id arg, NSUInteger matchs);

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
typedef ALSQLCondition *_Nullable (^ALSQLConditionBlock)(id cond);

@interface ALSQLCondition : NSObject

@property(readonly) NSString *sqlClause;
@property(readonly) NSArray  *sqlArguments;

+ (instancetype)conditionWithString:(NSString *)string args:(nullable id)arg, ... NS_REQUIRES_NIL_TERMINATION;
- (instancetype)initWithString:(NSString *)string args:(nullable id)arg, ... NS_REQUIRES_NIL_TERMINATION;

- (ALSQLConditionBlock)AND;
- (ALSQLConditionBlock)OR;

- (instancetype)build;

@end

@interface NSString (ALSQLCondition)
- (ALSQLCondition *)SQLCondition;
@end

@interface ALSQLExpression (ALSQLCondition)
- (ALSQLCondition *)SQLCondition;
@end

NS_ASSUME_NONNULL_END
