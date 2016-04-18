//
//  ALSQLCondition.m
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALSQLCondition.h"
#import "BlocksKit.h"
#import "NSString+Helper.h"



NS_ASSUME_NONNULL_BEGIN

#define addConditionArgs()  \
do {                    \
va_list args;       \
va_start(args, arg);\
[self addConditionArgsWithFirst:arg vaList:args];\
va_end(args);       \
} while(NO)

@implementation ALSQLCondition {
    @package
    NSMutableString  *_conditionClause;
    NSMutableArray   *_conditionArgs;
    
    BOOL             _isNested;
    BOOL             _hasLowerPriorityOperator; // eg: OR
    BOOL             _needWrappedByParentheses;
}

+ (instancetype)conditionWithString:(NSString *)string args:(nullable id)arg, ... NS_REQUIRES_NIL_TERMINATION {
    ALSQLCondition *condition = [[self alloc] initWithString:string args:nil];
    if ([arg isKindOfClass:[NSArray class]]) {
        [condition->_conditionArgs addObjectsFromArray:(NSArray *)arg];
    } else {
        va_list args;
        va_start(args, arg);
        [condition addConditionArgsWithFirst:arg vaList:args];
        va_end(args);
    }
    
    return condition;
}

- (instancetype)initWithString:(NSString *)string args:(nullable id)arg, ... NS_REQUIRES_NIL_TERMINATION {
    NSParameterAssert(string.length > 0);
    self = [super init];
    if (self) {
        _conditionClause  = [NSMutableString stringWithFormat:@"(%@)", string];
        _conditionArgs    = [NSMutableArray array];
        if ([arg isKindOfClass:[NSArray class]]) {
            [_conditionArgs addObjectsFromArray:(NSArray *)arg];
        } else {
            addConditionArgs();
        }
    }
    return self;
}

- (void)addConditionArgsWithFirst:(id)arg vaList:(va_list)args {
    id a = arg;
    while (a != nil) {
        [_conditionArgs addObject:a];
        a = va_arg(args, id);
    }
}

- (nullable NSString *)stringify {
    return self.sqlClause;
}

- (void)joinObject:(id)obj withOperator:(NSString *)op {
    if ([obj isKindOfClass:[ALSQLCondition class]]) {
        ALSQLCondition *cond = (ALSQLCondition *)obj;
        [cond build];
        [_conditionClause appendFormat:@" %@ %@", [op uppercaseString], cond.sqlClause];
        [_conditionArgs   addObjectsFromArray:cond.sqlArguments];
    } else {
        ALSQLExpression *exp = obj;
        if (![obj isKindOfClass:[ALSQLExpression class]]) {
            exp = [ALSQLExpression expressionWithValue:obj];
        }
        [_conditionClause appendFormat:@" %@ %@", [op uppercaseString], exp.stringify];
    }
    _isNested = YES;
}

- (ALSQLConditionBlock)AND {
    return ^(id cond) {
        [self joinObject:cond withOperator:@"AND"];
        //_needWrappedByParentheses = YES;
        return self;
    };
}

- (ALSQLConditionBlock)OR {
    return ^(id cond) {
        [self joinObject:cond withOperator:@"OR"];
        _hasLowerPriorityOperator = YES;
        _needWrappedByParentheses = YES;
        return self;
    };
}


- (instancetype)build {
#if DEBUG
    NSUInteger argCount = [_conditionClause occurrencesCountOfString:@"?"];
    NSAssert(argCount == _conditionArgs.count, @"Incorrect of sql arguments count");
#endif
    if (_needWrappedByParentheses ) {
        [_conditionClause insertString:@"(" atIndex:0];
        [_conditionClause appendString:@")"];
        _needWrappedByParentheses = NO;
    }
    return self;
}

- (NSString *)sqlClause {
    return [_conditionClause copy];
}

- (NSArray *)sqlArguments {
    return [_conditionArgs copy];
}

- (NSString *)description {
    return [[super description] stringByAppendingFormat:@"\nsql:%@\nargs:%@", self.sqlClause, self.sqlArguments];
}

@end


@implementation NSString (ALSQLCondition)
- (ALSQLCondition *)SQLCondition {
    return [ALSQLCondition conditionWithString:self args:nil];
}
@end

@implementation ALSQLExpression (ALSQLCondition)
- (ALSQLCondition *)SQLCondition {
    return [ALSQLCondition conditionWithString:self.stringify args:nil];
}
@end

@implementation NSObject (ALSQLCondition)

- (ALSQLConditionBlock)EQ {
    return ^ALSQLCondition *_Nullable (id condition) {
        return EQ(self, condition);
    };
}

- (ALSQLConditionBlock)LT {
    return ^ALSQLCondition *_Nullable (id condition) {
        return LT(self, condition);
    };
}

- (ALSQLConditionBlock)GT {
    return ^ALSQLCondition *_Nullable (id condition) {
        return GT(self, condition);
    };
}

- (ALSQLConditionBlock)NLT {
    return ^ALSQLCondition *_Nullable (id condition) {
        return NLT(self, condition);
    };
}

- (ALSQLConditionBlock)NGT {
    return ^ALSQLCondition *_Nullable (id condition) {
        return NGT(self, condition);
    };
}

- (ALSQLConditionBlock)NEQ {
    return ^ALSQLCondition *_Nullable (id condition) {
        return NEQ(self, condition);
    };
}

- (ALSQLConditionBlock)IN {
    return ^ALSQLCondition *_Nullable (id condition) {
        return IN(self, condition);
    };
}

- (ALSQLConditionBlock)LIKE {
    return ^ALSQLCondition *_Nullable (id condition) {
        return LIKE(self, condition);
    };
}

- (ALSQLConditionLikeBlock)MATCHS_SUBFIX {
    return ^ALSQLCondition *_Nullable (id condition, NSUInteger matches) {
        return MATCHS_SUBFIX(self, condition, matches);
    };
}

- (ALSQLConditionLikeBlock)MATCHS_PREFIX {
    return ^ALSQLCondition *_Nullable (id condition, NSUInteger matches) {
        return MATCHS_PREFIX(self, condition, matches);
    };
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

static FORCE_INLINE ALSQLCondition *expression(id name, NSString *op, id _Nullable value) {
    __stringifyExpressionOrReturnNil(name);
    if ([value isKindOfClass:[ALSQLExpression class]]) {
        return [ALSQLCondition conditionWithString:[NSString stringWithFormat:@"%@ %@ %@",
                                                    name,
                                                    op,
                                                    ((ALSQLExpression *) value).stringify]
                                              args:nil];
    }
    return [ALSQLCondition conditionWithString:[NSString stringWithFormat:@"%@ %@ ?", name, op]
                                          args:wrapNil(value), nil];
}


FORCE_INLINE ALSQLExpression *AS_EXP(id exp) {
    return [ALSQLExpression expressionWithValue:exp];
}

FORCE_INLINE static ALSQLCondition *_Nullable conditionWithObject(id obj) {
    if ([obj isKindOfClass:[ALSQLCondition class]]) {
        return obj;
    }
    if (![obj isKindOfClass:[ALSQLExpression class]]) {
        obj = [ALSQLExpression expressionWithValue:obj];
    }
    return [obj SQLCondition];
}

FORCE_INLINE ALSQLCondition *AND(NSArray *conditions) {
    if (![conditions isKindOfClass:[NSArray class]]) {
        ALLogWarn(@"*** argument:'conditions' should be kind of NSArray");
        return nil;
    }

    return [[(NSArray *) conditions bk_reduce:nil
                                    withBlock:^ALSQLCondition *(ALSQLCondition *result, id obj) {
                                        return result == nil ? [conditionWithObject(obj) build] : result.AND(obj);
                                    }] build];
}

FORCE_INLINE ALSQLCondition *OR(NSArray *conditions) {
    if (![conditions isKindOfClass:[NSArray class]]) {
        ALLogWarn(@"*** argument:'conditions' should be kind of NSArray");
        return nil;
    }
    
    return [[(NSArray *) conditions bk_reduce:nil
                                    withBlock:^ALSQLCondition *(ALSQLCondition *result, id obj) {
                                        return result == nil ? [conditionWithObject(obj) build] : result.OR(obj);
                                    }] build];
}

FORCE_INLINE ALSQLCondition *EQ(id column, id value) {
    return expression(column, @"=", value);
}

FORCE_INLINE ALSQLCondition *LT(id column, id value) {
    return expression(column, @"<", value);
}

FORCE_INLINE ALSQLCondition *GT(id column, id value) {
    return expression(column, @">", value);
}

FORCE_INLINE ALSQLCondition *NLT(id column, id value) {
    return expression(column, @">=", value);
}

FORCE_INLINE ALSQLCondition *NGT(id column, id value) {
    return expression(column, @"<=", value);
}

FORCE_INLINE ALSQLCondition *NEQ  (id exp, id value) {
    return expression(exp, @"!=", value);
}

FORCE_INLINE ALSQLCondition *IS_NULL(id column) {
    __stringifyExpressionOrReturnNil(column);
    return [ALSQLCondition conditionWithString:[column stringByAppendingString:@" IS NULL"] args:nil];
}

FORCE_INLINE ALSQLCondition *IS_NOT_NULL(id column) {
    __stringifyExpressionOrReturnNil(column);
    return [ALSQLCondition conditionWithString:[column stringByAppendingString:@" IS NOT NULL"] args:nil];
}

FORCE_INLINE ALSQLCondition *NOT (id expression) {
    __stringifyExpressionOrReturnNil(expression);
    return [ALSQLCondition conditionWithString:[NSString stringWithFormat:@"! %@", expression] args:nil];
}

FORCE_INLINE ALSQLCondition *IN(id expression, NSArray *values){
    __stringifyExpressionOrReturnNil(expression);
    if (values != nil && [expression isKindOfClass:[NSString class]]) {
        NSString *inStr = [[values bk_map:^NSString *(id obj) {
            return @"?";
        }] componentsJoinedByString:@", "];
        inStr = [NSString stringWithFormat:@"%@ IN (%@)", expression, inStr];
        return [ALSQLCondition conditionWithString:inStr args:values, nil];
    }
    return nil;
}

FORCE_INLINE ALSQLCondition *LIKE(id column, NSString *likeExpression) {
    __stringifyExpressionOrReturnNil(column);
    
    if ([column isKindOfClass:[NSString class]] && [likeExpression isKindOfClass:[NSString class]]) {
        return [ALSQLCondition conditionWithString:[NSString stringWithFormat:@"%@ LIKE ?", column] args:likeExpression, nil];
    }
    return nil;
}

const NSUInteger matchsAny = 0; //using %, eg: LIKE 'aaa%'

static FORCE_INLINE NSString *CHAR_LIKE(NSUInteger matchNum) {
    if (matchNum > 100) {
        NSCAssert(NO, @"WTH!!! Are you sure it's not a joke?");
        matchNum = 100;
    }
    NSMutableString *likeStr = [NSMutableString string];
    for (NSInteger i = 0; i < matchNum; ++i) {
        [likeStr appendString:@"_"];
    }
    return likeStr;
}

//eg: LIKE '%aaaaa'
//or: LIKE '_aaaaa'
FORCE_INLINE ALSQLCondition *MATCHS_SUBFIX(id column, id arg, NSUInteger matchs) {
    __stringifyExpressionOrReturnNil(column);
    
    NSString *exp = [arg stringify];
    if (exp == nil) {
        return nil;
    }
    if (matchs == matchsAny) {
        exp = [@"%" stringByAppendingString:exp];
    } else {
        exp = [CHAR_LIKE(matchs) stringByAppendingString:exp];
    }
    return LIKE(column, exp);
}

//eg: LIKE 'aaaaa%'
//or: LIKE 'aaaaa_'
FORCE_INLINE ALSQLCondition *MATCHS_PREFIX(id column, id arg, NSUInteger matchs) {
    __stringifyExpressionOrReturnNil(column);
    
    NSString *exp = [arg stringify];
    if (exp == nil) {
        return nil;
    }
    if (matchs == matchsAny) {
        exp = [exp stringByAppendingString:@"%"];
    } else {
        exp = [exp stringByAppendingString:CHAR_LIKE(matchs)];
    }
    return LIKE(column, exp);
}


NS_ASSUME_NONNULL_END
