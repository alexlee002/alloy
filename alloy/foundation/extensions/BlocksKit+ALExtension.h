//
//  BlocksKit+ALExtension.h
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - NSArray
@interface NSArray (ALBlocksKitExtension)

- (NSArray *)al_zip:(NSArray *)other, ... NS_REQUIRES_NIL_TERMINATION;

- (NSArray *)al_flatten;

- (NSArray *)al_flatMap:(id _Nullable (^)(id obj))block;

@end

@interface NSMutableArray (ALBlocksKitExtension)

- (void)al_performFlatMap:(id _Nullable(^)(id obj))block;

@end

#pragma mark - NSDictionary
@interface NSDictionary (ALBlocksKitExtension)

- (NSDictionary *)al_flatMap:(id _Nullable(^)(id key, id obj))block;

@end

@interface NSMutableDictionary (ALBlocksKitExtension)

- (void)al_performFlatMap:(id _Nullable(^)(id key, id obj))block;

@end

#pragma mark - NSSet
@interface NSSet (ALBlocksKitExtension)

- (NSSet *)al_flatMap:(id _Nullable(^)(id obj))block;

@end

@interface NSMutableSet (ALBlocksKitExtension)

- (void)al_performFlatMap:(id _Nullable(^)(id obj))block;

@end

#pragma mark - NSOrderedSet
@interface NSOrderedSet (ALBlocksKitExtension)

- (NSOrderedSet *)al_flatMap:(id _Nullable(^)(id obj))block;

@end

@interface NSMutableOrderedSet (ALBlocksKitExtension)

- (void)al_performFlatMap:(id _Nullable(^)(id obj))block;

@end

NS_ASSUME_NONNULL_END
