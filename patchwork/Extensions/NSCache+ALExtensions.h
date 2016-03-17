//
//  NSCache+ALExtensions.h
//  Pods
//
//  Created by Alex Lee on 3/13/16.
//
//

#import <Foundation/Foundation.h>

@interface NSCache (ALExtensions)

+ (instancetype)sharedCache;

// util methods
- (NSDateFormatter *)dateFormatterWithFormat:(NSString *)format;

@end
