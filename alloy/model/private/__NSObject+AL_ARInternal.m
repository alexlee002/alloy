//
//  NSObject+AL_ARInternal.m
//  alloy
//
//  Created by Alex Lee on 05/09/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSString+ALHelper.h"
#import "ALStringInflector.h"

@interface NSObject (AL_ARInternal)

@end

@implementation NSObject (AL_ARInternal)

+ (nullable NSString *)tableName {
    NSString *name = NSStringFromClass(self);
    if ([name hasSuffix:@"Model"]) {
        name = [name substringToIndex:(name.length - @"Model".length)];
    }
    if ([name al_matchesPattern:@"\\w+$"]) {
        ALStringInflector *inflactor = [ALStringInflector defaultInflector];
        return [[inflactor pluralize:[inflactor singularize:name]] al_stringByConvertingCamelCaseToUnderscore];
    }
    return [[name al_stringByConvertingCamelCaseToUnderscore] stringByAppendingString:@"_list"];
}

@end
