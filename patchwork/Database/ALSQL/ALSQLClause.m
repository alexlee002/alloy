//
//  ALSQLClause.m
//  patchwork
//
//  Created by Alex Lee on 16/10/12.
//  Copyright © 2016年 Alex Lee. All rights reserved.
//

#import "ALSQLClause.h"
#import "NSString+Helper.h"
#import "ALLogger.h"
#import <sqlite3.h>
#import <BlocksKit.h>

@implementation ALSQLClause {
    NSString        *_SQLString;
    NSMutableArray  *_argValues;
}

+ (instancetype)SQLClauseWithString:(NSString *)sql, ...NS_REQUIRES_NIL_TERMINATION {
    NSMutableArray *array = [NSMutableArray array];
    va_list args;
    va_start(args, sql);
    id a = nil;
    while ((a = va_arg(args, id)) != nil) {
        [array addObject:a];
    }
    va_end(args);
    
    return [self SQLClauseWithString:sql argValues:array];
}

+ (instancetype)SQLClauseWithString:(NSString *)sql argValues:(NSArray *)argValues {
    return [[self alloc] initWithString:sql argValues:argValues];
}

- (instancetype)initWithString:(NSString *)sql argValues:(NSArray *)argValues {
    self = [super init];
    if (self) {
        _SQLString = [sql copy];
        _argValues = [argValues mutableCopy];
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    return [self.class SQLClauseWithString:_SQLString argValues:_argValues];
}


- (NSString *)SQLString {
    return _SQLString;
}

- (NSArray *)argValues {
    return _argValues;
}

- (NSString *)description {
    return [[super description] stringByAppendingFormat:@"; sql string: %@", self.SQLString];
}

- (NSString *)debugDescription {
    NSArray *args = self.argValues;
    NSInteger argCount = args.count;
    
    NSMutableString *sql = [self.SQLString mutableCopy];
    NSInteger index = 0;

    NSRange range = NSMakeRange(0, sql.length);
    while ((range = [sql rangeOfString:@"?" options:0 range:range]).location != NSNotFound && index < argCount) {
        id argVal = args[index];
        if ([argVal isKindOfClass:NSData.class]) {
            argVal = [(NSData *)argVal al_debugDescription];
        }
        NSString *valStr = [NSString stringWithFormat:@"{%@}", argVal];
        [sql replaceCharactersInRange:range withString:valStr];
        index ++;
        range.location = range.location + valStr.length;
        range.length = sql.length - range.location;
    }
    if (index != argCount) {
        ALLogWarn(@"arguments count is not expected.\nsql: %@; arguments count:%ld", self.SQLString, (long)argCount);
        return [NSString stringWithFormat:@"sql: %@\nargs: %@", self.SQLString, args];
    }
    
    return sql;
}

#pragma mark -
- (BOOL)isValid {
    return !isEmptyString(self.SQLString);
}

- (void)setArgValues:(NSArray * _Nullable)argValues {
    _argValues = [argValues mutableCopy];
}

- (void)appendArgValues:(NSArray *)argValues {
    [_argValues addObjectsFromArray:argValues];
}

@end

@implementation ALSQLClause(ALBlocksChain)

- (ALSQLClause *(^)(ALSQLClause *other, NSString *delimiter))APPEND {
    return ^ALSQLClause *(ALSQLClause *other, NSString *delimiter) {
        [self append:other withDelimiter:delimiter];
        return self;
    };
}

- (ALSQLClause *(^)(NSArray *values))SET_ARG_VALUES {
    return ^ALSQLClause *(NSArray * _Nullable values) {
        [self setArgValues:values];
        return self;
    };
}

- (ALSQLClause *(^)(NSArray *values))ADD_ARG_VALUES {
    return ^ALSQLClause *(NSArray * _Nullable values) {
        [self appendArgValues:values];
        return self;
    };
}

@end

@implementation ALSQLClause (BaseOperations)

- (void)append:(ALSQLClause *)other withDelimiter:(NSString *_Nullable)delimiter{
    [self append:other.SQLString argValues:other.argValues withDelimiter:delimiter];
}

- (void)append:(NSString *)sql argValues:(NSArray *)arguments withDelimiter:(NSString *_Nullable)delimiter {
    _SQLString = [stringOrEmpty(self.SQLString)
                  stringByAppendingFormat:@"%@%@", stringOrEmpty(castToTypeOrNil(delimiter, NSString)), sql];
    
    if (arguments.count > 0) {
        if (_argValues == nil) {
            _argValues = [NSMutableArray array];
        }
        [_argValues addObjectsFromArray:arguments];
    }
    
}

@end


@implementation NSObject (ALSQLClause)

- (ALSQLClause *)SQLClause {
    if ([self isKindOfClass:[NSString class]]) {
        return [ALSQLClause SQLClauseWithString:(NSString *)self argValues:nil];
    }
    if ([self isKindOfClass:[NSNumber class]]) {
        return [ALSQLClause SQLClauseWithString:((NSNumber *)self).stringValue argValues:nil];
    }
    if ([self isKindOfClass:[ALSQLClause class]]) {
        return (ALSQLClause *)self;
    }
    
    NSString *strVal = stringValue(self);
    if (strVal != nil) {
        return [ALSQLClause SQLClauseWithString:strVal argValues:nil];
    }
    return nil;
}

- (ALSQLClause *_Nullable)SQLClauseArgValue {
    id value = [self transformToAcceptableArgValue];
    if (value != nil) {
        return [@"?" SQLClauseWithArgValues:@[value]];
    }
    return nil;
}

- (BOOL)isAcceptableSQLArgClassType {
    return [self isKindOfClass:[NSString class]] || [self isKindOfClass:[NSNumber class]] ||
           [self isKindOfClass:[NSData class]]   || [self isKindOfClass:[NSDate class]];
}

- (nullable id)transformToAcceptableArgValue {
    id value = self;
    if (![self isAcceptableSQLArgClassType]) {
        value = stringValue(self);
        if (value == nil) {
            ALLogWarn(@"object of type:%@ can not be accepted as SQL Clause argument", self.class);
            return nil;
        }
    }
    return value;
}

@end

@implementation NSString (ALSQLClause)

- (ALSQLClause *)SQLClauseWithArgValues:(NSArray *)argValues {
    return [ALSQLClause SQLClauseWithString:self argValues:argValues];
}

@end

