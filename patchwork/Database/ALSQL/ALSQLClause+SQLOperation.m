//
//  ALSQLClause+SQLOperation.m
//  patchwork
//
//  Created by Alex Lee on 16/10/13.
//  Copyright © 2016年 Alex Lee. All rights reserved.
//

#import "ALSQLClause+SQLOperation.h"
#import "NSString+Helper.h"
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

static const NSInteger kALSQLOperatorPriorityUninitialized = 0;
// 1 -> N : hight -> low
static const NSInteger kALSQLOperatorPriorityAND           = 1;
static const NSInteger kALSQLOperatorPriorityOR            = 2;

@interface ALSQLClause (SQLOperation)

- (void)operation:(NSString *)operatorName
         priority:(NSInteger)priority
         position:(ALOperatorPos)pos
      otherClause:(ALSQLClause *_Nullable)other;

@end

@implementation ALSQLClause (SQLOperation)

static void *kCurrentOPPriorityKey = &kCurrentOPPriorityKey;
- (void)setCurrentOPPriority:(NSInteger)priority {
    objc_setAssociatedObject(self, kCurrentOPPriorityKey, @(priority), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSInteger)currentOPPriority {
    return [ALCastToTypeOrNil(objc_getAssociatedObject(self, kCurrentOPPriorityKey), NSNumber) integerValue];
}

- (BOOL)hasInitializeCurrentOPPriority {
    return [self currentOPPriority] != 0;
}

- (void)operation:(NSString *)operatorName
         priority:(NSInteger)priority
         position:(ALOperatorPos)pos
      otherClause:(ALSQLClause *_Nullable)other {
    
    ALParameterAssert(!al_isEmptyString(operatorName));
    
    if (pos == ALOperatorPosLeft) {
        [self enclosingByBrackets];
        
        NSString *delimiter = nil;
        if ([operatorName rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]].length == operatorName.length) {
            delimiter = @" ";
        }
        [self appendAfterSQLString:al_stringOrEmpty(operatorName) withDelimiter:delimiter];
    } else if (pos == ALOperatorPosMid) {
        ALParameterAssert([other isValid]);
        
        if ([self priorityLowerThan:priority]) {
            [self enclosingByBrackets];
            [self setCurrentOPPriority:priority];
        }
        
        if ([other priorityLowerThan:priority]) {
            [other enclosingByBrackets];
        }
        
        NSString *op = al_stringOrEmpty(operatorName);
        [self appendSQLString:op argValues:nil withDelimiter:op.length > 0 ? @" " : nil];
        [self append:other withDelimiter:al_isEmptyString(self.SQLString) ? nil : @" "];
        
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

- (BOOL)priorityLowerThan:(NSInteger)priority {
    NSInteger current = [self currentOPPriority];
    return current > 0 && priority < current;
}

- (ALSQLClause *(^)(id obj))OR {
    return ^ALSQLClause *(id obj) {
        
        ALSQLClause *other = nil;
        if ([obj isKindOfClass:ALSQLClause.class]) {
            other = (ALSQLClause *)obj;
        } else {
            other = [obj al_SQLClauseByUsingAsArgValue];
        }
        
        [self operation:@"OR" priority:kALSQLOperatorPriorityOR position:ALOperatorPosMid otherClause:other];
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
        
        [self operation:@"AND" priority:kALSQLOperatorPriorityAND position:ALOperatorPosMid otherClause:other];
        return self;
    };
}

@end

AL_FORCE_INLINE ALSQLClause *sql_op_mid(ALSQLClause *src, NSString *optor, NSInteger priority, ALSQLClause *other) {
    [src operation:optor priority:priority position:ALOperatorPosMid otherClause:other];
    return src;
}

AL_FORCE_INLINE ALSQLClause *sql_op_left(NSString *optor, ALSQLClause *target) {
    [target operation:optor priority:kALSQLOperatorPriorityUninitialized position:ALOperatorPosLeft otherClause:nil];
    return target;
}

AL_FORCE_INLINE ALSQLClause *sql_op_right(ALSQLClause *target, NSString *optor) {
    [target operation:optor priority:kALSQLOperatorPriorityUninitialized position:ALOperatorPosRight otherClause:nil];
    return target;
}


#define __verifySelf()                                          \
    ALSQLClause *mine = nil;                                    \
    if ([self isKindOfClass:ALSQLSelectStatement.class]) {      \
        mine = [(ALSQLSelectStatement *)self asSubQuery];       \
    } else {                                                    \
        mine = [self al_SQLClause];                             \
    }                                                           \
    if (mine == nil) {                                          \
        return al_safeBlocksChainObj(nil, ALSQLClause);         \
    }

/**
 *  use an operator with specified 'name' to join two expressions.
 *  @param  name    operation name
 *  @param  op      the operator
 *  @param  accept_raw_val  if NO, only ALSQLClause is accepted, argument would be try to cast to ALSQLClause if it is not type of ALSQLClause,
 *                          otherwise, any object(normally should be ALSQLClause, NSString, NSNumber) are accepted.
 */
#define __SYNTHESIZE_MID_OP(name, op, arg_type, accept_raw_val)                 \
- (ALSQLClause *(^)(arg_type obj))name {                                        \
    return ^ALSQLClause *(arg_type obj) {                                       \
        __verifySelf();                                                         \
        if (!(accept_raw_val) ||([obj isKindOfClass:[ALSQLClause class]])) {    \
            ALSQLClause *other = [obj al_SQLClause];                            \
            ALAssert(other != nil, @"unsupported type of argument 'obj'");      \
            [mine operation:(op) priority:kALSQLOperatorPriorityUninitialized position:ALOperatorPosMid otherClause:other];  \
        } else {                                                                \
            ALSQLClause *other = [@"?" al_SQLClauseWithArgValues:@[obj]];       \
            [mine operation:(op) priority:kALSQLOperatorPriorityUninitialized position:ALOperatorPosMid otherClause:other];  \
        }                                                                       \
        return mine;                                                            \
    };                                                                          \
}

#define __SYNTHESIZE_SIDE_OP(name, op, op_pos)      \
- (ALSQLClause *(^)())name {                        \
    return ^ALSQLClause *() {                       \
        __verifySelf();                             \
        [mine operation:(op) priority:kALSQLOperatorPriorityUninitialized position:(op_pos) otherClause:nil];     \
        return mine;                                \
    };                                              \
}

@implementation NSObject (SQLOperation)

__SYNTHESIZE_MID_OP(SQL_EQ,  @"=",  id, YES);
__SYNTHESIZE_MID_OP(SQL_NEQ, @"!=", id, YES);

__SYNTHESIZE_MID_OP(SQL_LT,  @"<",  id, YES);
__SYNTHESIZE_MID_OP(SQL_NLT, @">=", id, YES);

__SYNTHESIZE_MID_OP(SQL_GT,  @">",  id, YES);
__SYNTHESIZE_MID_OP(SQL_NGT, @"<=", id, YES);

__SYNTHESIZE_MID_OP(SQL_LIKE, @"LIKE", id, YES);

// select * from test where not (c2 = 'aa' or c2 = 'bb');
//__SYNTHESIZE_SIDE_OP(NOT,           @"NOT",         ALOperatorPosLeft);
//__SYNTHESIZE_SIDE_OP(IS_NULL,       @"IS NULL",     ALOperatorPosRight);
//__SYNTHESIZE_SIDE_OP(IS_NOT_NULL,   @"IS NOT NULL", ALOperatorPosRight);


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

- (ALSQLClause *)inClause:(id)args orNotIn:(BOOL)notIn {
    __verifySelf();
    
    ALSQLClause *other = nil;
    if ([args isKindOfClass:[NSArray class]]) {
        NSString *placeholder = [[((NSArray *)args) bk_map:^NSString *(id obj) {
            return @"?";
        }] componentsJoinedByString:@", "];
        
        other = [placeholder al_SQLClauseWithArgValues:(NSArray *)args];
    } else if ([args isKindOfClass:[ALSQLClause class]]) {
        other = args;
    } else if ([args isKindOfClass:[NSString class]]) {
        other = [args SQLClause];
    }
    
    if (other) {
        [other enclosingByBrackets];
        [mine operation:notIn ? @"NOT IN" : @"IN" priority:kALSQLOperatorPriorityUninitialized position:ALOperatorPosMid otherClause:other];
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


//- (ALSQLClause *(^)(id _Nullable obj))CASE {
//    return ^ALSQLClause *(id obj) {
//        __verifySelf();
//        
//        NSString *clause = mine.SQLString;
//        [mine append:[ALSQLClause SQLCase:obj]
//       withDelimiter:al_isEmptyString(clause) || [clause hasSuffix:@" "] ? nil : @" "];
//        return mine;
//    };
//}

//+(ALSQLClause *)SQLCase:(id _Nullable)obj {
//    ALSQLClause *caseExp = [@"CASE" al_SQLClause];
//    if ([obj isKindOfClass:NSString.class]) {
//        [caseExp appendSQLString:(NSString *)obj argValues:nil withDelimiter:@" "];
//    }
//    else if ([obj isKindOfClass:ALSQLClause.class]) {
//        [caseExp append:(ALSQLClause *)obj withDelimiter:@" "];
//    }
//    else {
//        ALSQLClause *val = [obj SQLClause];
//        if (val != nil) {
//            [caseExp append:val withDelimiter:@" "];
//        }
//        else {
//            NSString *str = al_stringValue(obj);
//            if (!al_isEmptyString(str)) {
//                [caseExp appendSQLString:str argValues:nil withDelimiter:@" "];
//            }
//        }
//    }
//    return caseExp;
//}

//__SYNTHESIZE_MID_OP (WHEN, @"WHEN", id, YES);
//__SYNTHESIZE_MID_OP (THEN, @"THEN", id, YES);
//__SYNTHESIZE_MID_OP (ELSE, @"ELSE", id, YES);
//__SYNTHESIZE_SIDE_OP(END,  @"END",  ALOperatorPosRight);


__SYNTHESIZE_SIDE_OP(SQL_ASC,  @"ASC",  ALOperatorPosRight);
__SYNTHESIZE_SIDE_OP(SQL_DESC, @"DESC", ALOperatorPosRight);

__SYNTHESIZE_MID_OP(SQL_AS, @"AS", NSString *, NO);

@end
