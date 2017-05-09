//
//  ALSQLClause+SQLOperation.m
//  patchwork
//
//  Created by Alex Lee on 16/10/13.
//  Copyright © 2016年 Alex Lee. All rights reserved.
//

#import "ALSQLClause+SQLOperation.h"
#import "NSString+ALHelper.h"
#import <BlocksKit.h>
#import "SafeBlocksChain.h"
#import <objc/runtime.h>
#import "ALLogger.h"
#import "ALSQLSelectStatement.h"
#import "ALUtilitiesHeader.h"

typedef NS_ENUM(NSInteger, ALOperatorPos) {
    ALOperatorPosLeft = 1,
    ALOperatorPosMid,
    ALOperatorPosRight
};

const NSInteger kALSQLOperatorPrecedenceUninitialized = 0;
/**
 *  @see: http://www.sqlite.org/lang_expr.html
 SQLite understands the following binary operators, in order from highest to lowest precedence:
 
 ||
 *    /    %
 +    -
 <<   >>   &    |
 <    <=   >    >=
 =    ==   !=   <>   IS   IS NOT   IN   LIKE   GLOB   MATCH   REGEXP
 AND
 OR
 
 Supported unary prefix operators are these:
 
 -    +    ~    NOT
 
 *
 */
#define KALSQLOperatorPrecedenceDict  \
    @{                          \
       @"||" :  @1,             \
       /* --------*/            \
       @"*" :   @2,             \
       @"/" :   @2,             \
       @"%" :   @2,             \
       /* --------*/            \
       @"+" :   @3,             \
       @"-" :   @3,             \
       /* --------*/            \
       @"<<" :  @4,             \
       @">>" :  @4,             \
       @"&" :   @4,             \
       @"|" :   @4,             \
       /* --------*/            \
       @"<" :   @5,             \
       @"<=" :  @5,             \
       @">" :   @5,             \
       @">=" :  @5,             \
       /* --------*/            \
       @"=" :       @6,         \
       @"==" :      @6,         \
       @"!=" :      @6,         \
       @"<>" :      @6,         \
       @"IS" :      @6,         \
       @"IS NOT" :  @6,         \
       @"IN" :      @6,         \
       @"LIKE" :    @6,         \
       @"GLOB" :    @6,         \
       @"MATCH" :   @6,         \
       @"REGEXP" :  @6,         \
       /* --------*/            \
       @"AND" :     @7,         \
       /* --------*/            \
       @"OR" :      @8,         \
    }

AL_FORCE_INLINE NSInteger sql_operator_precedence(NSString *optr) {
    return [KALSQLOperatorPrecedenceDict[optr] integerValue];
}

@interface ALSQLClause (SQLOperation)

- (void)operation:(NSString *)operatorName
       precedence:(NSInteger)priority
         position:(ALOperatorPos)pos
      otherClause:(ALSQLClause *_Nullable)other;

@end

@implementation ALSQLClause (SQLOperation)

static void *kCurrentOptrPrecedenceKey = &kCurrentOptrPrecedenceKey;
- (void)setCurrentOptrPrecedence:(NSInteger)precedence {
    objc_setAssociatedObject(self, kCurrentOptrPrecedenceKey, @(precedence), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSInteger)currentOptrPrecedence {
    return [ALCastToTypeOrNil(objc_getAssociatedObject(self, kCurrentOptrPrecedenceKey), NSNumber) integerValue];
}

- (BOOL)hasInitializeCurrentOPPriority {
    return [self currentOptrPrecedence] != 0;
}

- (void)operation:(NSString *)operatorName
       precedence:(NSInteger)priority
         position:(ALOperatorPos)pos
      otherClause:(ALSQLClause *_Nullable)other {
    
    ALParameterAssert(!al_isEmptyString(operatorName));
    
    if (pos == ALOperatorPosLeft) {
        [self enclosingByBrackets];
        
        NSString *delimiter = nil;
        static NSCharacterSet *NonLettersSet = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NonLettersSet = [[NSCharacterSet letterCharacterSet] invertedSet];
        });
        if ([operatorName rangeOfCharacterFromSet:NonLettersSet].length == 0) {
            delimiter = @" ";
        }
        [self appendAfterSQLString:al_stringOrEmpty(operatorName) withDelimiter:delimiter];
    } else if (pos == ALOperatorPosMid) {
        ALParameterAssert([other isValid]);
        
        if ([self precedenceLowerThan:priority]) {
            [self enclosingByBrackets];
        }
        
        if ([other precedenceLowerThan:priority]) {
            [other enclosingByBrackets];
        }
        
        NSString *op = al_stringOrEmpty(operatorName);
        [self appendSQLString:op argValues:nil withDelimiter:op.length > 0 ? @" " : nil];
        [self append:other withDelimiter:al_isEmptyString(self.SQLString) ? nil : @" "];
        [self setCurrentOptrPrecedence:priority];
        
    } else if (pos == ALOperatorPosRight) {
        NSString *op = al_stringOrEmpty(operatorName);
        
        [self enclosingByBrackets];
        [self appendSQLString:op argValues:nil withDelimiter:op.length > 0 ? @" " : nil];
    }
}

- (void)enclosingByBrackets {
    [self appendAfterSQLString:@"(" withDelimiter:nil];
    [self appendSQLString:@")" argValues:nil withDelimiter:nil];
}

- (BOOL)precedenceLowerThan:(NSInteger)priority {
    NSInteger current = [self currentOptrPrecedence];
    return current != kALSQLOperatorPrecedenceUninitialized && priority < current;
}

- (ALSQLClause *(^)(id obj))OR {
    return ^ALSQLClause *(id obj) {
        
        ALSQLClause *other = nil;
        if ([obj isKindOfClass:ALSQLClause.class]) {
            other = (ALSQLClause *)obj;
        } else {
            other = [obj al_SQLClauseByUsingAsArgValue];
        }
        
        [self operation:@"OR" precedence:sql_operator_precedence(@"OR") position:ALOperatorPosMid otherClause:other];
        return self;
    };
}

- (ALSQLClause *(^)(id obj))AND {
    return ^ALSQLClause *(id obj) {
        
        ALSQLClause *other = nil;
        if ([obj isKindOfClass:ALSQLClause.class]) {
            other = (ALSQLClause *)obj;
        } else {
            other = [obj al_SQLClauseByUsingAsArgValue];
        }
        
        [self operation:@"AND" precedence:sql_operator_precedence(@"AND") position:ALOperatorPosMid otherClause:other];
        return self;
    };
}

@end

ALSQLClause *sql_op_mid(ALSQLClause *src, NSString *optor, NSInteger priority, ALSQLClause *other) {
    [src operation:optor precedence:priority position:ALOperatorPosMid otherClause:other];
    return src;
}

ALSQLClause *sql_op_left(NSString *optor, ALSQLClause *target) {
    [target operation:optor precedence:kALSQLOperatorPrecedenceUninitialized position:ALOperatorPosLeft otherClause:nil];
    return target;
}

ALSQLClause *sql_op_right(ALSQLClause *target, NSString *optor) {
    [target operation:optor precedence:kALSQLOperatorPrecedenceUninitialized position:ALOperatorPosRight otherClause:nil];
    return target;
}

#define __verifySelf()                                     \
    ALSQLClause *mine = nil;                               \
    if ([self isKindOfClass:ALSQLSelectStatement.class]) { \
        mine = [(ALSQLSelectStatement *) self asSubQuery]; \
    } else {                                               \
        mine = [self al_SQLClause];                        \
    }                                                      \
    if (mine == nil) {                                     \
        return al_safeBlocksChainObj(nil, ALSQLClause);    \
    }

/**
 *  use an operator with specified 'name' to join two expressions.
 *  @param  name    operation name
 *  @param  op      the operator
 *  @param  accept_raw_val  if NO, only ALSQLClause is accepted, argument would be try to cast to ALSQLClause if it is
 * not type of ALSQLClause,
 *                          otherwise, any object(normally should be ALSQLClause, NSString, NSNumber) are accepted.
 */
#define __SYNTHESIZE_MID_OP(name, op, arg_type, accept_raw_val)      \
    -(ALSQLClause * (^)(arg_type obj)) name {                        \
        return ^ALSQLClause *(arg_type obj) {                        \
            __verifySelf();                                          \
            ALSQLClause *other = __prepare_arg(obj, accept_raw_val); \
            [mine operation:(op)                                     \
                 precedence:sql_operator_precedence((op))            \
                   position:ALOperatorPosMid                         \
                otherClause:other];                                  \
            return mine;                                             \
        };                                                           \
    }

#define __prepare_arg(obj, accept_raw_val)                                  \
    ({                                                                      \
        ALSQLClause *other = nil;                                           \
        id arg = (obj);                                                     \
        if (!(accept_raw_val) || [arg isKindOfClass:[ALSQLClause class]]) { \
            other = [arg al_SQLClause];                                     \
            ALAssert(other != nil, @"unsupported type of argument 'obj'");  \
        } else if ([arg isKindOfClass:ALSQLSelectStatement.class]) {        \
            other = [(ALSQLSelectStatement *) arg asSubQuery];              \
        } else {                                                            \
            other = [@"?" al_SQLClauseWithArgValues:@[ arg ]];              \
        }                                                                   \
        other;                                                              \
    })

#define __SYNTHESIZE_SIDE_OP(name, op, op_pos)                                                                        \
    -(ALSQLClause * (^)()) name {                                                                                     \
        return ^ALSQLClause *() {                                                                                     \
            __verifySelf();                                                                                           \
            [mine operation:(op) precedence:kALSQLOperatorPrecedenceUninitialized position:(op_pos) otherClause:nil]; \
            return mine;                                                                                              \
        };                                                                                                            \
    }

@implementation NSObject (SQLOperation)

#pragma mark - value compare
__SYNTHESIZE_MID_OP(SQL_EQ,  @"=",  id, YES);
__SYNTHESIZE_MID_OP(SQL_NEQ, @"!=", id, YES);

__SYNTHESIZE_MID_OP(SQL_LT,  @"<",  id, YES);
__SYNTHESIZE_MID_OP(SQL_NLT, @">=", id, YES);

__SYNTHESIZE_MID_OP(SQL_GT,  @">",  id, YES);
__SYNTHESIZE_MID_OP(SQL_NGT, @"<=", id, YES);

#pragma mark - AND / OR
- (ALSQLClause *(^)(id obj))SQL_OR {
    return ^ALSQLClause *(id obj) {
        __verifySelf();
        
        return mine.OR(obj);
    };
}

- (ALSQLClause *(^)(id obj))SQL_AND {
    return ^ALSQLClause *(id obj) {
        __verifySelf();
        
        return mine.AND(obj);
    };
}

#pragma mark - IN
- (ALSQLClause *)inClause:(id)args orNotIn:(BOOL)notIn {
    __verifySelf();
    
    ALSQLClause *other = nil;
    if ([args isKindOfClass:[NSArray class]]) {
        NSString *placeholder = [[((NSArray *)args) bk_map:^NSString *(id obj) {
            return @"?";
        }] componentsJoinedByString:@", "];
        
        other = [placeholder al_SQLClauseWithArgValues:(NSArray *)args];
        [other enclosingByBrackets];
    } else if ([args isKindOfClass:[NSString class]]) {
        other = [args al_SQLClause];
        [other enclosingByBrackets];
    } else if ([args isKindOfClass:[ALSQLClause class]]) {
        other = args;
        [other enclosingByBrackets];
    } else if ([args isKindOfClass:[ALSQLSelectStatement class]]) {
        other = [(ALSQLSelectStatement *)args asSubQuery];
    }
    
    if (other) {
        [mine operation:notIn ? @"NOT IN" : @"IN" precedence:kALSQLOperatorPrecedenceUninitialized position:ALOperatorPosMid otherClause:other];
    } else {
        ALAssert(NO, @"unsupported type of argument 'obj'");
    }
    
    return mine;
}

- (ALSQLClause *(^)(id obj))SQL_IN {
    return ^ALSQLClause *(id obj) {
        return [self inClause:obj orNotIn:NO];
    };
}

- (ALSQLClause *(^)(id obj))SQL_NOT_IN {
    return ^ALSQLClause *(id obj) {
        return [self inClause:obj orNotIn:YES];
    };
}

#pragma mark - search (LIKE)
__SYNTHESIZE_MID_OP(SQL_LIKE, @"LIKE", id, YES);

- (ALSQLClause *(^)(id obj))SQL_PREFIX_LIKE {
    return ^ALSQLClause *(id obj) {
        __verifySelf();
        
        return self.SQL_LIKE([self likeClauseWith:obj isPrefix:YES]);
    };
}

- (ALSQLClause *(^)(id obj))SQL_SUBFIX_LIKE {
    return ^ALSQLClause *(id obj) {
        __verifySelf();
        
        return self.SQL_LIKE([self likeClauseWith:obj isPrefix:NO]);
    };
}

- (ALSQLClause *)likeClauseWith:(id)obj isPrefix:(BOOL)isPrefix {
    NSString *sql = nil;
    NSArray *values = nil;
    if ([obj isKindOfClass:[ALSQLClause class]]) {
        ALSQLClause *other = (ALSQLClause *)obj;
        if (isPrefix) {
            sql = [other.SQLString stringByAppendingString:@"%"];
        } else {
            sql = [@"%" stringByAppendingString:other.SQLString];
        }
        values = other.argValues;
    } else {
        NSString *value = al_stringValue(obj);
        ALAssert(value != nil, @"unsupported type of argument 'obj'");
        value = al_stringOrEmpty(value);
        value = isPrefix ? [value stringByAppendingString:@"%"] : [@"%" stringByAppendingString:value];
        sql = @"?";
        values = @[value];
    }
    return [sql al_SQLClauseWithArgValues:values];
}

#pragma mark -
__SYNTHESIZE_MID_OP(SQL_IS,     @"IS",      id, YES);
__SYNTHESIZE_MID_OP(SQL_IS_NOT, @"IS NOT",  id, YES);
// select * from test where not (c2 = 'aa' or c2 = 'bb');
__SYNTHESIZE_SIDE_OP(SQL_NOT,   @"NOT",     ALOperatorPosLeft);

- (ALSQLClause *(^)())SQL_ISNULL {
    return ^ALSQLClause *{
        return self.SQL_IS([@"NULL" al_SQLClause]);
    };
}

- (ALSQLClause *(^)())SQL_NOTNULL {
    return ^ALSQLClause *{
        __verifySelf();
        
        [mine appendSQLString:@"NOT NULL" argValues:nil withDelimiter:@" "];
        return mine;
    };
}

__SYNTHESIZE_SIDE_OP(SQL_ASC,  @"ASC",  ALOperatorPosRight);
__SYNTHESIZE_SIDE_OP(SQL_DESC, @"DESC", ALOperatorPosRight);

__SYNTHESIZE_MID_OP(SQL_AS, @"AS", NSString *, NO);

#pragma mark -

- (ALSQLClause *(^)(id x, id y))SQL_BETWEEN {
    return ^ALSQLClause *(id x, id y) {
        __verifySelf();
        
        //@see:http://www.sqlite.org/lang_expr.html#collateop "The BETWEEN operator"
        NSInteger precedence = sql_operator_precedence(@"LIKE");
        ALSQLClause *l = __prepare_arg(x, YES);
        ALSQLClause *r = __prepare_arg(y, YES);
        
        ALParameterAssert([l isValid] && [r isValid]);
        if ([mine precedenceLowerThan:precedence]) {
            [mine enclosingByBrackets];
        }
        
        if ([l precedenceLowerThan:precedence]) {
            [l enclosingByBrackets];
        }
        
        if ([r precedenceLowerThan:precedence]) {
            [r enclosingByBrackets];
        }
        
        [mine append:l withDelimiter:@" BETWEEN "];
        [mine append:r withDelimiter:@" AND "];
        return mine;
    };
}

- (ALSQLClause *(^)(id exp))SQL_ESCAPE {
    return ^ALSQLClause *(id exp) {
        __verifySelf();
        
        ALSQLClause *arg = __prepare_arg(exp, YES);
        [mine append:arg withDelimiter:@" ESCAPE "];
        return mine;
    };
}

- (ALSQLClause *(^)(id exp))SQL_COLLATE {
    return ^ALSQLClause *(id exp) {
        __verifySelf();
        
        ALSQLClause *arg = __prepare_arg(exp, NO);
        [mine append:arg withDelimiter:@" COLLATE "];
        return mine;
    };
}

@end


@implementation ALSQLClause (AL_Common_sqlClauses)

//http://www.sqlite.org/lang_expr.html
//CASE x WHEN w1 THEN r1 WHEN w2 THEN r2 ELSE r3 END
//CASE WHEN x=w1 THEN r1 WHEN x=w2 THEN r2 ELSE r3 END
// eg: select c1 from test where case c2 when (select 'aa') then NULL else 'AA' end is null;
+ (ALSQLClause *)sql_case:(nullable id)c when:(id)w then:(id)t else:(id)z {
    ALSQLClause *mine = [@"CASE" al_SQLClause];
    
    if (c != nil) {
        ALSQLClause *c1 = __prepare_arg(c, NO);
        [mine append:c1 withDelimiter:@" "];
    }
    
    ALSQLClause *w1 = __prepare_arg(w, YES);
    [mine append:w1 withDelimiter:@" WHEN "];
    
    ALSQLClause *t1 = __prepare_arg(t, YES);
    [mine append:t1 withDelimiter:@" THEN "];
    if (z != nil) {
        ALSQLClause *z1 = __prepare_arg(z, YES);
        [mine append:z1 withDelimiter:@" ELSE "];
    }
    return mine;
}

- (ALSQLClause *)sql_when:(id)w then:(id)t else:(id)z {
    ALSQLClause *w1 = __prepare_arg(w, YES);
    [self append:w1 withDelimiter:@" WHEN "];
    
    ALSQLClause *t1 = __prepare_arg(t, YES);
    [self append:t1 withDelimiter:@" THEN "];
    
    ALSQLClause *z1 = __prepare_arg(z, YES);
    [self append:z1 withDelimiter:@" ELSE "];
    
    return self;
}

- (ALSQLClause *)sql_when:(id)w then:(id)t {
    ALSQLClause *w1 = __prepare_arg(w, YES);
    [self append:w1 withDelimiter:@" WHEN "];
    
    ALSQLClause *t1 = __prepare_arg(t, YES);
    [self append:t1 withDelimiter:@" THEN "];
    return self;
}

- (ALSQLClause *)sql_case_end {
    [self appendSQLString:@"END" argValues:nil withDelimiter:@" "];
    return self;
}
@end
