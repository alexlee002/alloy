//
//  ALSQLExpression.h
//  patchwork
//
//  Created by Alex Lee on 3/21/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN
@class ALSQLExpression;
/**
 *  jon expressions via operator
 *  eg: (col1 & 2)
 *
 *  @param exp1     ALSQLExpression or NSString
 *  @param optor
 *  @param exp2     ALSQLExpression or NSString
 *
 *  @return ALSQLExpression
 */
extern ALSQLExpression *EXP_OP  (id exp1, NSString *optor, id exp2);
extern ALSQLExpression *BIT_AND (id exp1, id exp2);
extern ALSQLExpression *BIT_OR  (id exp1, id exp2);
extern ALSQLExpression *BIT_XOR (id exp1, id exp2);
extern ALSQLExpression *BIT_NOT (id exp1, id exp2);

extern ALSQLExpression *ASC_ORDER (id expression);
extern ALSQLExpression *DESC_ORDER(id expression);

/**
 *  An indicator to mark the value as a SQL expression (not a value type)
 *  @see ALSQLCondition, if a value of condition is type of ALSQLExpression, it won't be represented by a '?'.
 *  eg: 
 *      EQ(@"col1", @2), the sql clause would be "col1 = ?"
 *      EQ(@"col1", AS_EXP(@"col2")), the sql clause would be "col1 = col2"
 *
 */
@interface ALSQLExpression : NSObject

@property(readonly) NSString *stringify;

+ (nullable instancetype)expressionWithValue:(id)value;

@end


@interface NSString (ALSQLExpression)

- (ALSQLExpression *)SQLExpression;

@end

@interface NSNumber (ALSQLExpression)

- (ALSQLExpression *)SQLExpression;

@end


typedef ALSQLExpression *_Nullable (^ALSQLExpressionOperationBlock)(id _Nonnull expression);
typedef ALSQLExpression *_Nullable (^ALSQLExpressionOperationBlockExt)(NSString *_Nonnull op, id _Nonnull expression);

@interface NSObject (ALSQLExpression)

- (nullable ALSQLExpression *)SQLExpression;

@property(readonly) ALSQLExpressionOperationBlockExt EXP_OPERATEION;
@property(readonly) ALSQLExpressionOperationBlock    BIT_AND;
@property(readonly) ALSQLExpressionOperationBlock    BIT_OR;
@property(readonly) ALSQLExpressionOperationBlock    BIT_XOR;
@property(readonly) ALSQLExpressionOperationBlock    BIT_NOT;

@end

NS_ASSUME_NONNULL_END

#pragma mark - internal macros

#ifndef __stringifyExpressionOrReturnNil
    #define __stringifyExpressionOrReturnNil(exp) \
        if ([(exp) isKindOfClass:[ALSQLExpression class]]) { \
            (exp) = ((ALSQLExpression *)(exp)).stringify;    \
        }                                                    \
        if (![(exp) isKindOfClass:[NSString class]]) {       \
            ALLogWarn(@"*** argument:'%s' should not be nil", #exp);\
            return nil;                                      \
        }
#endif
