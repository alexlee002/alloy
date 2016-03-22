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
