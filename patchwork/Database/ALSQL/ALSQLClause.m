//
//  ALSQLClause.m
//  patchwork
//
//  Created by Alex Lee on 16/10/12.
//  Copyright © 2016年 Alex Lee. All rights reserved.
//

#import "ALSQLClause.h"
#import "NSString+ALHelper.h"
#import "ALLogger.h"
#import "ALUtilitiesHeader.h"
#import <sqlite3.h>
#import <BlocksKit.h>


@implementation ALSQLClause {
    NSMutableString  *_SQLString;
    NSMutableArray   *_argValues;
}

+ (instancetype)SQLClauseWithString:(NSString *)sql, ...NS_REQUIRES_NIL_TERMINATION {
    al_guard_or_return(sql != nil, nil);
    
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
        _SQLString = [sql mutableCopy];
        _argValues = [argValues mutableCopy];
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    return [self.class SQLClauseWithString:_SQLString argValues:_argValues];
}


- (NSString *)SQLString {
    return [_SQLString copy];
}

- (NSArray *)argValues {
    return [_argValues copy];
}

- (BOOL)isValid {
    return !al_isEmptyString(self.SQLString);
}

- (void)setSQLString:(NSString *)string {
    _SQLString = [string mutableCopy];
}

- (void)setArgValues:(NSArray *)argValues {
    _argValues = [argValues mutableCopy];
}
@end

@implementation ALSQLClause (BaseOperations)

- (void)append:(ALSQLClause *)other withDelimiter:(NSString *_Nullable)delimiter{
    al_guard_or_return([other isKindOfClass:ALSQLClause.class], AL_VOID);
    [self appendSQLString:other.SQLString argValues:other.argValues withDelimiter:delimiter];
}

- (void)appendSQLString:(NSString *)sql argValues:(NSArray *)arguments withDelimiter:(NSString *)delimiter {
    sql = ALCastToTypeOrNil(sql, NSString);
    if (_SQLString == nil) {
        _SQLString = [sql mutableCopy];
    } else {
        [_SQLString appendString:al_stringOrEmpty(ALCastToTypeOrNil(delimiter, NSString))];
        [_SQLString appendString:al_stringOrEmpty(sql)];
    }
    
    if (arguments.count > 0) {
        if (_argValues == nil) {
            _argValues = [NSMutableArray array];
        }
        [_argValues addObjectsFromArray:arguments];
    }
    
}

- (void)appendAfterSQLString:(NSString *)sql withDelimiter:(NSString *_Nullable)delimiter {
    al_guard_or_return([sql isKindOfClass:NSString.class], AL_VOID);
    if (ALCastToTypeOrNil(delimiter, NSString) != nil) {
        [_SQLString insertString:delimiter atIndex:0];
    }
    [_SQLString insertString:sql atIndex:0];
}

@end

@implementation ALSQLClause(ALBlocksChain)

- (ALSQLClause *(^)(id obj, NSString *delimiter))APPEND {
    return ^ALSQLClause *(id obj, NSString *delimiter) {
        if ([obj isKindOfClass:NSString.class]) {
            [self appendSQLString:obj argValues:nil withDelimiter:delimiter];
        } else if ([obj isKindOfClass:ALSQLClause.class]) {
            [self append:obj withDelimiter:delimiter];
        } else {
            ALSQLClause *clause = [obj al_SQLClause];
            [self append:clause withDelimiter:delimiter];
        }
        return self;
    };
}

- (ALSQLClause *(^)(NSArray *values))SET_ARG_VALUES {
    return ^ALSQLClause *(NSArray * _Nullable values) {
        [self setArgValues:values];
        return self;
    };
}

@end

#pragma mark - debug
@interface ALSQLClause (ALDebug)
@end
@implementation ALSQLClause(ALDebug)

- (NSString *)description {
    return [NSString stringWithFormat:@"sql: %@\nargs: %@", self.SQLString, self.argValues];
}

- (NSString *)debugDescription {
    NSString *sql = self.SQLString;
    NSArray *args = [self.argValues copy];
    NSInteger argCount = args.count;
    
    NSMutableString *desc = [NSMutableString string];
    NSInteger lastLocation = 0;
    NSInteger argIndex = 0;
    NSRange range = NSMakeRange(0, sql.length);
    
    while ((range = [sql rangeOfString:@"?" options:0 range:range]).location != NSNotFound && argIndex < argCount) {
        id argVal = args[argIndex];
        if ([argVal isKindOfClass:NSData.class]) {
            argVal = [(NSData *)argVal al_debugDescription];
        }
        
        [desc appendString:[sql substringToIndex:range.location]];
        [desc appendFormat:@"'%@'", argVal];
        
        lastLocation += range.length;
        argIndex ++;

        range.location += range.length;
        range.length = sql.length - range.location;
        
    }
    if (lastLocation < sql.length) {
        [desc appendString:[sql substringFromIndex:lastLocation]];
    }
    if (argIndex != argCount) {
        ALLogWarn(@"arguments count is not expected.\nsql: %@; arguments count:%ld", self.SQLString, (long)argCount);
        return [NSString stringWithFormat:@"sql: %@\nargs: %@", self.SQLString, args];
    }
    
    return desc;
}

@end


@implementation NSObject (ALSQLClause)

- (ALSQLClause *)al_SQLClause {
    if ([self isKindOfClass:[NSString class]]) {
        return [ALSQLClause SQLClauseWithString:(NSString *)self argValues:nil];
    }
    if ([self isKindOfClass:[NSNumber class]]) {
        return [ALSQLClause SQLClauseWithString:((NSNumber *)self).stringValue argValues:nil];
    }
    if ([self isKindOfClass:[ALSQLClause class]]) {
        return (ALSQLClause *)self;
    }
    
    NSString *strVal = al_stringValue(self);
    if (strVal != nil) {
        return [ALSQLClause SQLClauseWithString:strVal argValues:nil];
    }
    return nil;
}

- (ALSQLClause *_Nullable)al_SQLClauseByUsingAsArgValue {
    id value = [self transformToAcceptableArgValue];
    if (value != nil) {
        return [@"?" al_SQLClauseWithArgValues:@[value]];
    }
    return nil;
}

- (BOOL)al_isAcceptableSQLArgClassType {
    return [self isKindOfClass:[NSString class]] || [self isKindOfClass:[NSNumber class]] ||
           [self isKindOfClass:[NSData class]]   || [self isKindOfClass:[NSDate class]];
}

- (nullable id)transformToAcceptableArgValue {
    id value = self;
    if (![self al_isAcceptableSQLArgClassType]) {
        value = al_stringValue(self);
        if (value == nil) {
            ALLogWarn(@"object of type:%@ can not be accepted as SQL Clause argument", self.class);
            return nil;
        }
    }
    return value;
}

@end

@implementation NSString (ALSQLClause)

- (ALSQLClause *)al_SQLClauseWithArgValues:(NSArray *)argValues {
    return [ALSQLClause SQLClauseWithString:self argValues:argValues];
}

- (ALSQLClause *)al_SQLClauseByAppendingSQLClause:(ALSQLClause *)sql withDelimiter:(NSString *)delimiter {
    ALSQLClause *retVal = [self al_SQLClause];
    al_guard_or_return([sql isKindOfClass:ALSQLClause.class], retVal);
    [retVal append:sql withDelimiter:delimiter];
    return retVal;
}

- (ALSQLClause *)al_SQLClauseByAppendingSQL:(NSString *)sql argValues:(NSArray *)argValues delimiter:(NSString *)delimiter {
    ALSQLClause *retVal = [self al_SQLClause];
    [retVal appendSQLString:sql argValues:argValues withDelimiter:delimiter];
    return retVal;
}

@end

