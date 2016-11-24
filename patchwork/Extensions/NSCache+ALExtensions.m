//
//  NSCache+ALExtensions.m
//  Pods
//
//  Created by Alex Lee on 3/13/16.
//
//

#import "NSCache+ALExtensions.h"
#import "NSString+Helper.h"

@implementation NSCache (ALExtensions)

+ (instancetype)sharedCache {
    static NSCache *kSharedCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kSharedCache = [[NSCache alloc] init];
        kSharedCache.name           = @"common_shared_cache";
        kSharedCache.countLimit     = 1024;
        kSharedCache.totalCostLimit = 5 * 1024 * 1024; // 5MB
    });
    return kSharedCache;
}


- (id)objectForKey:(id)key defaultValue:(id)dftVal cacheDefaultValue:(BOOL)cache {
    id obj = [self objectForKey:key];
    if (obj == nil) {
        obj = dftVal;
        if (dftVal != nil && cache) {
            [self setObject:dftVal forKey:key];
        }
    }
    return obj;
}


- (NSDateFormatter *)dateFormatterWithFormat:(NSString *)format {
    if (isEmptyString(format)) {
        return nil;
    }
    NSString *key = [@"NSDateFormatter_$_" stringByAppendingString:format];
    NSDateFormatter *df = [self objectForKey:key];
    if (df == nil) {
        df = [[NSDateFormatter alloc] init];
        df.dateFormat = format;
        [self setObject:df forKey:key];
    }
    if (![df isKindOfClass:[NSDateFormatter class]]) {
        NSAssert(NO, @"return value is not NSDateFormatter instance");
        df = nil;
    }
    return df;
}

@end
