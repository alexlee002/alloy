//
//  NSCache+ALExtensions.h
//  Pods
//
//  Created by Alex Lee on 3/13/16.
//
//

#import <Foundation/Foundation.h>

@interface NSCache (ALExtensions)

+ (instancetype)al_sharedCache;

- (id)al_objectForKey:(id)key defaultValue:(id)dftVal cacheDefaultValue:(BOOL)cache;

// util methods
- (NSDateFormatter *)al_dateFormatterWithFormat:(NSString *)format;

@end
