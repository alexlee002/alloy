//
//  ALFMDatabaseQueue.h
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class FMDatabase;
@interface ALFMDatabaseQueue : NSObject
@property(nonatomic, readonly, nullable) NSString *path;

- (instancetype)initWithPath:(nullable NSString*)aPath;

- (void)close;

- (void)inDatabase:(void (^)(FMDatabase *db))block;

- (void)inTransaction:(void (^)(FMDatabase *db, BOOL *rollback))block;

- (void)inDeferredTransaction:(void (^)(FMDatabase *db, BOOL *rollback))block;

@end

NS_ASSUME_NONNULL_END