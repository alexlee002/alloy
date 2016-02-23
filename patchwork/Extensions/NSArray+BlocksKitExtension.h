//
//  NSArray+BlocksKitExtension.h
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray (BlocksKitExtension)

- (NSArray *)al_zip:(NSArray *)other, ... NS_REQUIRES_NIL_TERMINATION;

- (NSArray *)al_flatten;

@end


NS_ASSUME_NONNULL_END
