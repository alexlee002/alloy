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

@property(readonly, nullable) NSString *path;

- (nullable instancetype)initWithPath:(nullable NSString*)aPath;
- (nullable instancetype)initWithPath:(nullable NSString*)aPath flags:(int)openFlags;

- (void)close;

- (void)inDatabase:(void (^)(FMDatabase *db))block;

- (void)inTransaction:(void (^)(FMDatabase *db, BOOL *rollback))block;

- (void)inDeferredTransaction:(void (^)(FMDatabase *db, BOOL *rollback))block;

@end

@interface ALFMDatabaseQueue (SavePoint)

//@see: FMDatabase
- (BOOL)startSavePointNamed:(NSString *)name error:(NSError*_Nullable *)outErr;
- (BOOL)releaseSavePointNamed:(NSString*)name error:(NSError*_Nullable*)outErr;
- (BOOL)rollbackToSavePointNamed:(NSString*)name error:(NSError*_Nullable*)outErr;
- (nullable NSError *)inSavePoint:(void (^)(FMDatabase *db, BOOL *rollback))block;

@end

@interface ALFMDatabaseQueue (ALExtension)
@property(atomic, assign) BOOL shouldCacheStatements;
@end

NS_ASSUME_NONNULL_END
