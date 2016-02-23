//
//  ALSQLCondition.m
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALSQLCondition.h"
#import <BlocksKit.h>
#import "StringHelper.h"


NS_ASSUME_NONNULL_BEGIN

#define addConditionArgs()  \
do {                    \
va_list args;       \
va_start(args, arg);\
[self addConditionArgsWithFirst:arg vaList:args];\
va_end(args);       \
} while(NO)


//FORCE_INLINE NSArray *BIT_AND(NSString *column, id value) {
//    if ([value isKindOfClass:[NSString class]]) {
//        NSString *tmp = (NSString *)value;
//        if ([value hasPrefix:@"$"] && [value hasSuffix:@"$"]) {
//            column = [tmp substringWithRange:NSMakeRange(1, tmp.length - 2)];
//            return @[ [column stringByAppendingFormat:@" & (%@)", value] ];
//        }
//    }
//    return @[ [column stringByAppendingString:@" & ?"],  wrapNil(value) ];
//}


@implementation ALSQLCondition {
    @package
    NSMutableString *_sqlWhere;
    NSMutableArray  *_whereArgs;
    
    BOOL             _isNested;
    BOOL             _hasLowerPriorityOperator; // eg: OR
    BOOL             _needWrappedByParentheses;
}

+ (instancetype)conditionWithString:(NSString *)string args:(nullable id)arg, ... NS_REQUIRES_NIL_TERMINATION {
    ALSQLCondition *condition = [[self alloc] initWithString:string args:nil];
    if ([arg isKindOfClass:[NSArray class]]) {
        [condition->_whereArgs addObjectsFromArray:(NSArray *)arg];
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
        _sqlWhere  = [NSMutableString stringWithFormat:@"(%@)", string];
        _whereArgs = [NSMutableArray array];
        if ([arg isKindOfClass:[NSArray class]]) {
            [_whereArgs addObjectsFromArray:(NSArray *)arg];
        } else {
            addConditionArgs();
        }
    }
    return self;
}

- (void)addConditionArgsWithFirst:(id)arg vaList:(va_list)args {
    id a = arg;
    while (a != nil) {
        [_whereArgs addObject:a];
        a = va_arg(args, id);
    }
}


- (ALSQLConditionBlock)AND {
    return ^(ALSQLCondition *cond) {
        [cond build];
        [_sqlWhere appendFormat:@" AND %@", cond.sqlCondition];
        [_whereArgs addObjectsFromArray:cond.conditionArgs];
        
        _isNested = YES;
        //_needWrappedByParentheses = YES;
        return self;
    };
}

- (ALSQLConditionBlock)OR {
    return ^(ALSQLCondition *cond) {
        [cond build];
        [_sqlWhere appendString:@" OR "];
        [_sqlWhere appendString:cond.sqlCondition];
        [_whereArgs addObjectsFromArray:cond.conditionArgs];
        
        _isNested = YES;
        _hasLowerPriorityOperator = YES;
        _needWrappedByParentheses = YES;
        return self;
    };
}

- (instancetype)build {
#if DEBUG
    NSUInteger argCount = [_sqlWhere occurrencesCountOfString:@"?"];
    NSAssert(argCount == _whereArgs.count, @"Incorrect of sql arguments count");
#endif
    if (_needWrappedByParentheses ) {
        [_sqlWhere insertString:@"(" atIndex:0];
        [_sqlWhere appendString:@")"];
        _needWrappedByParentheses = NO;
    }
    return self;
}

- (NSString *)sqlCondition {
    return [_sqlWhere copy];
}

- (NSArray *)conditionArgs {
    return [_whereArgs copy];
}

- (NSString *)description {
    return [[super description] stringByAppendingFormat:@"\nsql:%@\nargs:%@", self.sqlCondition, self.conditionArgs];
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

static FORCE_INLINE NSString *_Nullable extractDBExp(NSString *exp) {
    exp = [exp stringify];
    if (exp == nil) {
        return nil;
    }
    if ([exp hasPrefix:@"$"] && [exp hasSuffix:@"$"]) {
        NSString *extract = [exp substringWithRange:NSMakeRange(1, exp.length - 2)];
        if (extract.length == 0) {
            return nil;
        }
        return extract;
    }
    return exp;
}

static FORCE_INLINE ALSQLCondition *expression(NSString *name, NSString *op, id _Nullable value) {
    if (![name isKindOfClass:[NSString class]]) {
        return nil;
    }
    if ([value isKindOfClass:[NSString class]]) {
        NSString *exp = extractDBExp(value);
        if (exp != nil && exp.length < ((NSString *)value).length) { // is DB expression
            return [ALSQLCondition conditionWithString:[NSString stringWithFormat:@"%@ %@ %@", name, op, exp] args: nil];
        }
    }
    return [ALSQLCondition conditionWithString:[NSString stringWithFormat:@"%@ %@ ?", name, op] args:wrapNil(value), nil];
}


FORCE_INLINE NSString *AS_EXP(NSString *exp) {
    return [NSString stringWithFormat:@"$%@$", exp];
}

FORCE_INLINE NS_REQUIRES_NIL_TERMINATION ALSQLCondition *AND(ALSQLCondition *cond, ...) {
    if (cond == nil) {
        return nil;
    }
    [cond build];
    ALSQLCondition *result = cond;
    va_list args;
    va_start(args, cond);
    while ((cond = va_arg(args, ALSQLCondition *)) != nil) {
        if (![cond isKindOfClass:[ALSQLCondition class]]) {
            NSCAssert(NO, @"arg in va_list is not a ALSQLCondition class!!!");
            continue;
        }
        result.AND(cond);
    }
    va_end(args);
    
    return [result build];
}

FORCE_INLINE NS_REQUIRES_NIL_TERMINATION ALSQLCondition *OR(ALSQLCondition *cond, ...) {
    if (cond == nil) {
        return nil;
    }
    
    [cond build];
    ALSQLCondition *result = cond;
    va_list args;
    va_start(args, cond);
    while ((cond = va_arg(args, ALSQLCondition *)) != nil) {
        if (![cond isKindOfClass:[ALSQLCondition class]]) {
            NSCAssert(NO, @"arg in va_list is not a ALSQLCondition class!!!");
            continue;
        }
        result.OR(cond);
    }
    va_end(args);
    
    return [result build];
}

FORCE_INLINE ALSQLCondition *EQ(NSString *column, id value) {
    return expression(column, @"=", value);
}

FORCE_INLINE ALSQLCondition *LT(NSString *column, id value) {
    return expression(column, @"<", value);
}

FORCE_INLINE ALSQLCondition *GT(NSString *column, id value) {
    return expression(column, @">", value);
}

FORCE_INLINE ALSQLCondition *NLT(NSString *column, id value) {
    return expression(column, @">=", value);
}

FORCE_INLINE ALSQLCondition *NGT(NSString *column, id value) {
    return expression(column, @"<=", value);
}

//FORCE_INLINE ALSQLCondition *BIT_AND (NSString *column, id value) {
//    return expression(column, @"&", value);
//}
//
//FORCE_INLINE ALSQLCondition *BIT_OR  (NSString *column, id value) {
//    return expression(column, @"|", value);
//}
//
//FORCE_INLINE ALSQLCondition *BIT_XOR (NSString *column, id value) {
//    return expression(column, @"^", value);
//}
//
//FORCE_INLINE ALSQLCondition *BIT_NOT (NSString *column, id value) {
//    return expression(column, @"~", value);
//}

FORCE_INLINE ALSQLCondition *IS_NULL(NSString *column) {
    return [ALSQLCondition conditionWithString:[column stringByAppendingString:@" IS NULL"] args:nil];
}

FORCE_INLINE ALSQLCondition *IS_NOT_NULL(NSString *column) {
    return [ALSQLCondition conditionWithString:[column stringByAppendingString:@" IS NOT NULL"] args:nil];
}

FORCE_INLINE NS_REQUIRES_NIL_TERMINATION ALSQLCondition *IN(NSString *column, id value, ...) {
    if (value != nil && [column isKindOfClass:[NSString class]]) {
        NSMutableArray  *inArgs = [NSMutableArray array];
        va_list args;
        va_start(args, value);
        while (value != nil) {
            [inArgs addObject:value];
            value = va_arg(args, id);
        }
        va_end(args);
        
        NSString *inStr = [[inArgs bk_map:^NSString *(id obj) {
            return @"?";
        }] componentsJoinedByString:@", "];
        inStr = [NSString stringWithFormat:@"%@ IN [%@]", column, inStr];
        return [ALSQLCondition conditionWithString:inStr args:inArgs, nil];
    }
    return nil;
}

FORCE_INLINE ALSQLCondition *LIKE(NSString *column, NSString *likeExpression) {
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
FORCE_INLINE ALSQLCondition *LEFT_LIKE(NSString *column, id arg, NSUInteger matchs) {
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
FORCE_INLINE ALSQLCondition *RIGHT_LIKE(NSString *column, id arg, NSUInteger matchs) {
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
