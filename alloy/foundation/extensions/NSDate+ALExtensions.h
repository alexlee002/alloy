//
//  NSDate+ALExtensions.h
//  Pods
//
//  Created by Alex Lee on 3/13/16.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDate (ALExtensions)
- (NSString *)al_stringWithFormat:(NSString *)format;

/// Parse date from formated string.
+ (nullable instancetype)al_dateFromFormattedString:(NSString *)string;
@end

NS_ASSUME_NONNULL_END
