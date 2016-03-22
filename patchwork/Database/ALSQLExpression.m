//
//  ALSQLExpression.m
//  patchwork
//
//  Created by Alex Lee on 3/21/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALSQLExpression.h"
#import "NSString+Helper.h"

@implementation ALSQLExpression

@synthesize stringify = _stringify;

+ (instancetype)expressionWithValue:(id)value {
    if ([value isKindOfClass:[ALSQLExpression class]]) {
        return value;
    }
    if (![value isKindOfClass:[NSString class]] && ![value isKindOfClass:[NSNumber class]]) {
        return nil;
    }
    ALSQLExpression *expression = [[self alloc] init];
    expression->_stringify = [[value stringify] copy];
    return expression;
}

- (NSString *)description {
    return self.stringify;
}

@end

@implementation NSString (ALSQLExpression)

- (ALSQLExpression *)SQLExpression {
    return [ALSQLExpression expressionWithValue:self];
}
@end


@implementation NSNumber (ALSQLExpression)

- (ALSQLExpression *)SQLExpression {
    return [ALSQLExpression expressionWithValue:self];
}

@end

@implementation NSObject (ALSQLExpression)

- (nullable ALSQLExpression *)SQLExpression {
    return [ALSQLExpression expressionWithValue:self];
}

- (ALSQLExpressionOperationBlockExt)EXP_OPERATEION {
    return ^ALSQLExpression *_Nullable (NSString *_Nonnull op, id _Nonnull expression) {
        return EXP_OP([self SQLExpression], op, expression);
    };
}

- (ALSQLExpressionOperationBlock)BIT_AND {
    return ^ALSQLExpression *_Nullable (id _Nonnull expression) {
        return BIT_AND([self SQLExpression], expression);
    };
}

- (ALSQLExpressionOperationBlock)BIT_OR{
    return ^ALSQLExpression *_Nullable (id _Nonnull expression) {
        return BIT_OR([self SQLExpression], expression);
    };
}

- (ALSQLExpressionOperationBlock)BIT_XOR{
    return ^ALSQLExpression *_Nullable (id _Nonnull expression) {
        return BIT_XOR([self SQLExpression], expression);
    };
}

- (ALSQLExpressionOperationBlock)BIT_NOT{
    return ^ALSQLExpression *_Nullable (id _Nonnull expression) {
        return BIT_NOT([self SQLExpression], expression);
    };
}

@end

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - functions

FORCE_INLINE ALSQLExpression *EXP_OP  (id exp1, NSString *op, id exp2) {
    __stringifyExpressionOrReturnNil(exp1);
    if (![exp2 isKindOfClass:[ALSQLExpression class]]) {
        exp2 = [ALSQLExpression expressionWithValue:exp2];
    }
    if (isEmptyString(op) || exp2 == nil) {
        return nil;
    }
    return [[exp1 stringByAppendingFormat:@" %@ %@", op, exp2] SQLExpression];
}

FORCE_INLINE ALSQLExpression *BIT_AND (id column, id value) {
    return EXP_OP(column, @"&", value);
}

FORCE_INLINE ALSQLExpression *BIT_OR  (id column, id value) {
    return EXP_OP(column, @"|", value);
}

FORCE_INLINE ALSQLExpression *BIT_XOR (id column, id value) {
    return EXP_OP(column, @"^", value);
}

FORCE_INLINE ALSQLExpression *BIT_NOT (id column, id value) {
    return EXP_OP(column, @"~", value);
}

FORCE_INLINE ALSQLExpression *ASC_ORDER (id expression) {
    __stringifyExpressionOrReturnNil(expression);
    return [[(NSString *)expression stringByAppendingString:@" ASC"] SQLExpression];
}

FORCE_INLINE ALSQLExpression *DESC_ORDER(id expression) {
    __stringifyExpressionOrReturnNil(expression);
    return [[(NSString *)expression stringByAppendingString:@" DESC"] SQLExpression];
}
