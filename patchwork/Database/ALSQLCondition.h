//
//  ALSQLCondition.h
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UtilitiesHeader.h"

NS_ASSUME_NONNULL_BEGIN

@class ALSQLCondition;

// mark 'exp' is an expression, not value
extern NSString *AS_EXP(NSString *exp);

extern ALSQLCondition *EQ   (NSString *column, id value);
extern ALSQLCondition *LT   (NSString *column, id value);
extern ALSQLCondition *GT   (NSString *column, id value);
extern ALSQLCondition *NLT  (NSString *column, id value);
extern ALSQLCondition *NGT  (NSString *column, id value);

//extern ALSQLCondition *BIT_AND (NSString *column, id value);
//extern ALSQLCondition *BIT_OR  (NSString *column, id value);
//extern ALSQLCondition *BIT_XOR (NSString *column, id value);
//extern ALSQLCondition *BIT_NOT (NSString *column, id value);

extern ALSQLCondition *IS_NULL(NSString *column);
extern ALSQLCondition *IS_NOT_NULL(NSString *column);

extern NS_REQUIRES_NIL_TERMINATION ALSQLCondition *IN(NSString *column, id value, ...);

// 'LIKE' pattern,
// matchsAny:           using "%"
// natural number(>0):  using "_"
extern const NSUInteger matchsAny;
extern ALSQLCondition *LIKE(NSString *column, NSString *likeExpression);
// eg: LIKE '%abc'
extern ALSQLCondition *LEFT_LIKE(NSString *column, id arg, NSUInteger matchs);
// eg: LIKE 'abc%'
extern ALSQLCondition *RIGHT_LIKE(NSString *column, id arg, NSUInteger matchs);

extern NS_REQUIRES_NIL_TERMINATION ALSQLCondition *AND(ALSQLCondition *cond, ...);
extern NS_REQUIRES_NIL_TERMINATION ALSQLCondition *OR(ALSQLCondition *cond, ...);

typedef NS_ENUM(NSInteger, DBValueType) {
    DBValueTypeNormal       = 0,
    DBValueTypeColumnName   = 1
};


typedef ALSQLCondition *_Nullable (^ALSQLConditionBlock)(ALSQLCondition *cond);

@interface ALSQLCondition : NSObject

@property(readonly) NSString *sqlCondition;
@property(readonly) NSArray  *conditionArgs;

+ (instancetype)conditionWithString:(NSString *)string args:(nullable id)arg, ... NS_REQUIRES_NIL_TERMINATION;
- (instancetype)initWithString:(NSString *)string args:(nullable id)arg, ... NS_REQUIRES_NIL_TERMINATION;

- (ALSQLConditionBlock)AND;
- (ALSQLConditionBlock)OR;

- (instancetype)build;


@end

NS_ASSUME_NONNULL_END
