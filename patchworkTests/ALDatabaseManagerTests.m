//
//  ALDatabaseManagerTests.m
//  patchwork
//
//  Created by 吴晓龙 on 16/10/12.
//  Copyright © 2016年 Alex Lee. All rights reserved.
//

#define EnableColorLog 0

#import <XCTest/XCTest.h>
#import "ALDBConnectionProtocol.h"
#import "ALDBMigrationProtocol.h"
#import <FMDatabase.h>
#import "ALDatabase.h"
#import "ALLogger.h"


NSString *testDBPath() {
    return [NSTemporaryDirectory() stringByAppendingPathComponent:@"patchwork-testcases.sqlite"];
}

@interface TestDBOpenHelper : NSObject <ALDBConnectionProtocol>
@end

@implementation TestDBOpenHelper

+ (BOOL)canHandleDatabaseWithPath:(NSString *)path {
    ALLogInfo(@"==================");
    return [path isEqualToString:testDBPath()];
}

- (void)databaseDidOpen:(FMDatabase *)db {
    ALLogInfo(@"==================");
    [db executeUpdate:@"PRAGMA journal_mode=WAL;"];
}

@end

@interface TestDBMigrationHandler : NSObject<ALDBMigrationProtocol>
@end

@implementation TestDBMigrationHandler

+ (BOOL)canMigrateDatabaseWithPath:(NSString *)path {
    ALLogInfo(@"******************");
    return [path isEqualToString:testDBPath()];
}

- (NSInteger)currentVersion {
    ALLogInfo(@"******************");
    return 3;
}

- (BOOL)migrateFromVersion:(NSInteger)fromVersion to:(NSInteger)toVersion databaseHandler:(FMDatabase *)db {
    ALLogInfo(@"****************** from version: %ld; to: %ld", (long)fromVersion, (long)toVersion);
    return YES;
}

- (BOOL)setupDatabase:(FMDatabase *)db {
    ALLogInfo(@"******************");
    return [db executeUpdate:@"CREATE TABLE IF NOT EXISTS users ("
            @"uid INTEGER PRIMARY KEY,  "
            @"name TEXT, "
            @"age INTEGER, "
            @"gender INTEGER, "
            @"email TEXT, "
            @"addr TEXT)"
            ];
}

@end


@interface ALDatabaseManagerTests : XCTestCase

@end

@implementation ALDatabaseManagerTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}


- (void)testDBOpen {
    NSString *dbpath = testDBPath();
    ALLogInfo(@"database path: %@", dbpath);
    [ALDatabase databaseWithPath:dbpath];
}

#define NS_BLOCK_ASSERTIONS 1
//- (void)testReadonlyDBOpen {
//    NSString *dbpath = testDBPath();
//    [[NSFileManager defaultManager] removeItemAtPath:dbpath error:nil];
//
//    ALDatabase *db = [ALDatabase databaseWithPath:dbpath];
//    BOOL ret = db.INSERT().INTO(@"users").VALUES_DICT(@{@"name": @"Alex Lee", @"age": @36}).EXECUTE_UPDATE(); // ✘
//    XCTAssertTrue(ret);
//    [db close];
//    
//    [[NSFileManager defaultManager] setAttributes:@{ NSFilePosixPermissions: [NSNumber numberWithShort:0444] } ofItemAtPath:dbpath error:nil];
//    db = [ALDatabase databaseWithPath:dbpath];
//    XCTAssertNotNil(db);
//    
//    ret = db.INSERT().INTO(@"users").VALUES_DICT(@{@"name": @"Alex Lee", @"age": @36}).EXECUTE_UPDATE();
//    XCTAssertFalse(ret);
//    
//    
//    db = [ALDatabase readonlyDatabaseWithPath:dbpath];
//    ALLogInfo(@"readonly DB: %@", db);
//    XCTAssertNotNil(db);
//    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        XCTAssertEqualObjects(db, [ALDatabase readonlyDatabaseWithPath:dbpath]);
//        
//        XCTAssertNotEqualObjects(db, [ALDatabase threadLocalReadonlyDatabaseWithPath:dbpath]);
//    });
//    
//    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:3]];
//    
//    [[NSFileManager defaultManager] removeItemAtPath:dbpath error:nil];
//}

- (void)testTooLongDBOperation {
//    [[ALDatabase databaseWithPath:testDBPath()].queue inDatabase:^(FMDatabase * _Nonnull db) {
//        CFTimeInterval t = CFAbsoluteTimeGetCurrent();
//        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:6]];
//        NSLog(@">>> %f", CFAbsoluteTimeGetCurrent() - t);
//    }];
//    
//    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
}


@end
