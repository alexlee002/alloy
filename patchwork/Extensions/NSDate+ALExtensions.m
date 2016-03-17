//
//  NSDate+ALExtensions.m
//  Pods
//
//  Created by Alex Lee on 3/13/16.
//
//

#import "NSDate+ALExtensions.h"
#import "NSCache+ALExtensions.h"

@implementation NSDate (ALExtensions)

- (NSString *)stringWithFormat:(NSString *)format {
    NSDateFormatter *df = [[NSCache sharedCache] dateFormatterWithFormat:format];
    return [df stringFromDate:self];
}

@end
