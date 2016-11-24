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

FORCE_INLINE ALSQLClause *SQLMidOp(ALSQLClause *target, NSString *optor, ALSQLClause *other) {
    [target operation:optor position:ALOperatorPosMid otherClause:other];
    return target;
}

FORCE_INLINE ALSQLClause *SQLLeftOp(NSString *optor, ALSQLClause *target) {
    [target operation:optor position:ALOperatorPosLeft otherClause:nil];
    return target;
}

FORCE_INLINE ALSQLClause *SQLRightOp(ALSQLClause *target, NSString *optor) {
    [target operation:optor position:ALOperatorPosRight otherClause:nil];
    return target;
}

@implementation ALSQLClause (SQLOperation)

- (void)operation:(NSString *)operatorName position:(ALOperatorPos)pos otherClause:(ALSQLClause *)other {
    NSParameterAssert(!isEmptyString(operatorName));
    
    if (pos == ALOperatorPosLeft) {
        [self setValue:[NSString stringWithFormat: @"%@ %@", stringOrEmpty(operatorName), stringOrEmpty(self.SQLString)]
                forKey:keypath(self.SQLString)];
    } else if (pos == ALOperatorPosMid) {
        NSParameterAssert([other isValid]);
        
        [self append:[NSString stringWithFormat:@"%@ %@", stringOrEmpty(operatorName), stringOrEmpty(other.SQLString)]
           argValues:other.argValues
       withDelimiter:isEmptyString(self.SQLString) ? nil : @" "];
    } else if (pos == ALOperatorPosRight) {
        [self setValue:[NSString stringWithFormat:@"%@ %@", stringOrEmpty(self.SQLString), stringOrEmpty(operatorName)]
                forKey:keypath(self.SQLString)];
    }
}



static void *kCurrentOPPriorityKey = &kCurrentOPPriorityKey;
- (void)setCurrentOPPriority:(NSInteger)priority {
    objc_setAssociatedObject(self, kCurrentOPPriorityKey, @(priority), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSInteger)currentOPPriority {
    return [castToTypeOrNil(objc_getAssociatedObject(self, kCurrentOPPriorityKey), NSNumber) integerValue];
}

- (BOOL)hasInitializeCurrentOPPriority {
    return [self currentOPPriority] != 0;
}

+ (NSInteger)operatorPriority:(NSString *)opName {
    opName = [opName uppercaseString];
    // ${priority} = ${operator index} + 1; 0 is uninitialized
    NSArray *descPriorityOPs = @[@"AND", @"OR"];
    NSInteger index = [descPriorityOPs indexOfObject:opName];
    if (index == NSNotFound) {
        ALLogError(@"*** Unsupported operation: '%@'", opName);
        return 0;
    }
    return index + 1;
}

- (BOOL)isHigherPriorityOP:(NSString *)opName {
    NSInteger priority = [ALSQLClause operatorPriority:opName];
    NSInteger current = [self currentOPPriority];
    
    return current > 0 && priority < current;
}

- (ALSQLClause *(^)(id obj))OR {
    return ^ALSQLClause *(id obj) {
        ALSQLClause *other = nil;
        if ([obj isKindOfClass:ALSQLClause.class]) {
            other = (ALSQLClause *)obj;
        } else {
            other = [obj SQLClauseArgValue];
        }
        
        NSString *opName = @"OR";
        [self operation:opName position:ALOperatorPosMid otherClause:other];
        [self setCurrentOPPriority:[ALSQLClause operatorPriority:opName]];
        return self;
    };
}

- (ALSQLClause *(^)(id obj))AND {
    return ^ALSQLClause *(id obj) {
        NSString *opName = @"AND";
        
        ALSQLClause *other = nil;
        if ([obj isKindOfClass:ALSQLClause.class]) {
            other = (ALSQLClause *)obj;
        } else {
            other = [obj SQLClauseArgValue];
        }
        
        if ([other isHigherPriorityOP:opName]) {
            other = [[NSString stringWithFormat:@"(%@)", other.SQLString] SQLClauseWithArgValues:other.argValues];
        }
        
        if ([self isHigherPriorityOP:opName]) {
            [self setValue:[NSString stringWithFormat:@"(%@)", self.SQLString] forKey:keypath(self.SQLString)];
        }
        
        [self operation:opName position:ALOperatorPosMid otherClause:other];
        [self setCurrentOPPriority:[ALSQLClause operatorPriority:opName]];
        
        return self;
    };
}


@end

#define __verifySelf()                              \
    ALSQLClause *mine = [self SQLClause];               \
    if (mine == nil) {                              \
        return SafeBlocksChainObj(nil, ALSQLClause);\
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
            ALSQLClause *other = [obj SQLClause];                               \
            NSAssert(other != nil, @"unsupported type of argument 'obj'");      \
            [mine operation:(op) position:ALOperatorPosMid otherClause:other];  \
        } else {                                                                \
            ALSQLClause *other = [@"?" SQLClauseWithArgValues:@[obj]];          \
            [mine operation:(op) position:ALOperatorPosMid otherClause:other];  \
        }                                                                       \
        return mine;                                                            \
    };                                                                          \
}

#define __SYNTHESIZE_SIDE_OP(name, op, op_pos)      \
- (ALSQLClause *(^)())name {                        \
    return ^ALSQLClause *() {                       \
        __verifySelf();                             \
        [mine operation:(op) position:(op_pos) otherClause:nil];     \
        return mine;                                \
    };                                              \
}

@implementation NSObject (SQLOperation)

//__SYNTHESIZE_MID_OP(AND, @"AND", NO);
//__SYNTHESIZE_MID_OP(OR,  @"OR",  NO);

__SYNTHESIZE_MID_OP(EQ,  @"=",  id, YES);
__SYNTHESIZE_MID_OP(NEQ, @"!=", id, YES);

__SYNTHESIZE_MID_OP(LT,  @"<",  id, YES);
__SYNTHESIZE_MID_OP(NLT, @">=", id, YES);

__SYNTHESIZE_MID_OP(GT,  @">",  id, YES);
__SYNTHESIZE_MID_OP(NGT, @"<=", id, YES);

__SYNTHESIZE_MID_OP(LIKE, @"LIKE", id, YES);

__SYNTHESIZE_SIDE_OP(NOT,           @"NOT",         ALOperatorPosLeft);
__SYNTHESIZE_SIDE_OP(IS_NULL,       @"IS NULL",     ALOperatorPosRight);
__SYNTHESIZE_SIDE_OP(IS_NOT_NULL,   @"IS NOT NULL", ALOperatorPosRight);


- (ALSQLClause *(^)(id obj))OR {
    return ^ALSQLClause *(id obj) {
        __verifySelf();
        
        return mine.OR(obj);
    };
}

- (ALSQLClause *(^)(id obj))AND {
    return ^ALSQLClause *(id obj) {
        __verifySelf();
        
        return mine.AND(obj);
    };
}

- (ALSQLClause *(^)(id obj))IN {
    return ^ALSQLClause *(id obj) {
        __verifySelf();
        
        ALSQLClause *other = nil;
        if ([obj isKindOfClass:[NSArray class]]) {
            NSString *placeholder = [[((NSArray *)obj) bk_map:^NSString *(id obj) {
                return @"?";
            }] componentsJoinedByString:@", "];
            
            other = [placeholder SQLClauseWithArgValues:(NSArray *)obj];
        } else if ([obj isKindOfClass:[ALSQLClause class]]) {
            other = obj;
        } else if ([obj isKindOfClass:[NSString class]]) {
            other = [obj SQLClause];
        }
        
        if (other) {
            [mine append:[NSString stringWithFormat:@"IN (%@)", stringOrEmpty(other.SQLString)]
               argValues:other.argValues
           withDelimiter:isEmptyString(mine.SQLString) ? nil : @" "];
        } else {
            NSAssert(NO, @"unsupported type of argument 'obj'");
        }
        
        return mine;
    };
}

- (ALSQLClause *(^)(id obj))PREFIX_LIKE {
    return ^ALSQLClause *(id obj) {
        __verifySelf();
        
        return self.LIKE([self likeClauseWith:obj isPrefix:YES]);
    };
}

- (ALSQLClause *(^)(id obj))SUBFIX_LIKE {
    return ^ALSQLClause *(id obj) {
        __verifySelf();
        
        return self.LIKE([self likeClauseWith:obj isPrefix:NO]);
    };
}

- (ALSQLClause *)likeClauseWith:(id)obj isPrefix:(BOOL)isPrefix {
    NSString *sql = nil;
    NSArray  *values = nil;
    if ([obj isKindOfClass:[ALSQLClause class]]) {
        ALSQLClause *other = (ALSQLClause *)obj;
        if (isPrefix) {
            sql = [other.SQLString stringByAppendingString:@"%"];
        } else {
            sql = [@"%" stringByAppendingString:other.SQLString];
        }
        values = other.argValues;
    } else {
        NSString *value = stringOrEmpty(stringValue(obj));
        value = isPrefix ? [value stringByAppendingString:@"%"] : [@"%" stringByAppendingString:value];
        sql = @"?";
        values = @[value];
    }
    return [sql SQLClauseWithArgValues:values];
}


- (ALSQLClause *(^)(id _Nullable obj))CASE {
    return ^ALSQLClause *(id obj) {
        __verifySelf();
        
        NSString *clause = mine.SQLString;
        [mine append:[ALSQLClause SQLCase:obj]
       withDelimiter:isEmptyString(clause) || [clause hasSuffix:@" "] ? nil : @" "];
        return mine;
    };
}

+(ALSQLClause *)SQLCase:(id _Nullable)obj {
    ALSQLClause *caseExp = [@"CASE" SQLClause];
    if ([obj isKindOfClass:NSString.class]) {
        [caseExp append:(NSString *)obj argValues:nil withDelimiter:@" "];
    }
    else if ([obj isKindOfClass:ALSQLClause.class]) {
        [caseExp append:(ALSQLClause *)obj withDelimiter:@" "];
    }
    else {
        ALSQLClause *val = [obj SQLClause];
        if (val != nil) {
            [caseExp append:val withDelimiter:@" "];
        }
        else {
            NSString *str = stringValue(obj);
            if (!isEmptyString(str)) {
                [caseExp append:str argValues:nil withDelimiter:@" "];
            }
        }
    }
    return caseExp;
}

__SYNTHESIZE_MID_OP (WHEN, @"WHEN", id, YES);
__SYNTHESIZE_MID_OP (THEN, @"THEN", id, YES);
__SYNTHESIZE_MID_OP (ELSE, @"ELSE", id, YES);
__SYNTHESIZE_SIDE_OP(END,  @"END",  ALOperatorPosRight);


__SYNTHESIZE_SIDE_OP(ASC,  @"ASC",  ALOperatorPosRight);
__SYNTHESIZE_SIDE_OP(DESC, @"DESC", ALOperatorPosRight);

__SYNTHESIZE_MID_OP(AS, @"AS", NSString *, NO);

@end
