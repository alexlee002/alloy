//
//  ALSQLClause.m
//  patchwork
//
//  Created by Alex Lee on 16/10/12.
//  Copyright © 2016年 Alex Lee. All rights reserved.
//

#import "ALSQLClause.h"
#import "NSString+Helper.h"

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
    return [[super debugDescription] stringByAppendingFormat:@"\nsql string: %@\narguments: %@", self.SQLString,
            self.argValues];
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

- (void)append:(ALSQLClause *)other withSpace:(BOOL)withSpace {
    [self append:other.SQLString argValues:other.argValues withSpace:withSpace];
}

- (void)append:(NSString *)sql argValues:(NSArray *)arguments withSpace:(BOOL)withSpace {
    _SQLString = [stringOrEmpty(self.SQLString) stringByAppendingFormat:@"%@%@", (withSpace ? @" " : @""), sql];
    
    if (_argValues == nil && arguments.count > 0) {
        _argValues = [NSMutableArray array];
    }
    [_argValues addObjectsFromArray:arguments];
}

@end

@implementation ALSQLClause(ALBlocksChain)

- (ALSQLClause *(^)(ALSQLClause *other, BOOL withSpace))APPEND {
    return ^ALSQLClause *(ALSQLClause *other, BOOL withSpace) {
        [self append:other withSpace:withSpace];
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


@implementation NSObject (ALSQLClause)

- (ALSQLClause *)toSQL {
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

- (ALSQLClause *_Nullable)SQLFromArgValue {
    if (stringValue(self) == nil) {
        return nil;
    }
    return [@"?" toSQLWithArgValues:@[self]];
}

@end

@implementation NSString (ALSQLClause)

- (ALSQLClause *)toSQLWithArgValues:(NSArray *)argValues {
    return [ALSQLClause SQLClauseWithString:self argValues:argValues];
}

@end

