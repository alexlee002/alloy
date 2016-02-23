//
//  ALDatabaseManager.m
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALDatabaseManager.h"
#import "ALDatabase.h"
#import "StringHelper.h"

NS_ASSUME_NONNULL_BEGIN

@implementation ALDatabaseManager {
    NSMutableDictionary<NSString *, ALDatabase *> *_databaseDict;
}
SYNTHESIZE_SINGLETON

- (instancetype)init {
    self = [super init];
    if (self) {
        _databaseDict = [NSMutableDictionary dictionary];
    }
    return self;
}

- (nullable ALDatabase *)databaseWithPath:(NSString *)filePath {
    filePath = [filePath stringify];
    if (filePath.length == 0) {
        return nil;
    }

    ALDatabase *db = _databaseDict[filePath];
    if (db == nil) {
        static dispatch_semaphore_t lock;
        dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
        // init db;
        //_databaseDict[filePath] = db;
        dispatch_semaphore_signal(lock);
    }
    return db;
}


@end

NS_ASSUME_NONNULL_END
