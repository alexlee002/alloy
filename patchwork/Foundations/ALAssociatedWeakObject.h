//
//  ALAssociatedWeakObject.h
//  MCLog
//
//  Created by Alex Lee on 1/9/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN
//@see: http://stackoverflow.com/questions/22809848/objective-c-runtime-run-code-at-deallocation-of-any-object/31560217#31560217
@interface NSObject (AssociatedWeakObject)

- (void)runAtDealloc:(void(^)(void))block;
- (void)setWeakAssociatedPropertyValue:(nullable NSObject *)value withAssociatedKey:(const void *)key;

@end
NS_ASSUME_NONNULL_END
