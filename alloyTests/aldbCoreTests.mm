//
//  aldbCoreTests.m
//  alloy
//
//  Created by Alex Lee on 18/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ALDatabase.h"
#import "ALDatabase+CoreDB.h"
#import "ALDBResultSet.h"
#import "database.hpp"
#import "statement_recyclable.hpp"

@interface aldbCoreTests : XCTestCase

@end

@implementation aldbCoreTests

static NSString *kPath = nil;
- (void)setUp {
    [super setUp];

    kPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    XCTAssertTrue(kPath.length > 0);
    kPath = [kPath stringByAppendingPathComponent:@"aldb-test.sqlite"];
    
    ALDatabase *database = [ALDatabase databaseWithPath:kPath keepAlive:YES];
    [database setConfig:[](std::shared_ptr<aldb::Handle> &handle, aldb::ErrorPtr &error) -> bool {
        handle->exec("PRAGMA cache_size=-2000");
        handle->exec("PRAGMA page_size=4096");
        handle->exec("PRAGMA locking_mode=NORMAL");
        handle->exec("PRAGMA synchronous=NORMAL");
        handle->exec("PRAGMA journal_mode=WAL");
        
        handle->register_sqlite_busy_handler([](void *h, int c)->int {
            sqlite3_sleep(MIN(pow(2, c), 64));
            return 1;
        });
        return true;
    } named:@"default"];
}

- (void)testCore {
    {
        aldb::Database db(kPath.UTF8String, {}, nullptr);
        db.exec("PRAGMA user_version=10;");
        aldb::RecyclableStatement stmt = db.prepare("PRAGMA user_version");
        stmt->step();
        aldb::RecyclableStatement stmt1 = stmt;
        stmt = nullptr;
        int32_t v = stmt1->get_int32_value(0);
        XCTAssertEqual(v, 10);
    }
    {
        aldb::Database db(kPath.UTF8String, {}, nullptr);
        db.exec("PRAGMA user_version=10;");
        aldb::RecyclableStatement stmt = db.prepare("PRAGMA user_version");
        ALDBResultSet *rs = [ALDBResultSet resultSetWithStatement:stmt];
        stmt = nullptr;
        NSInteger v = 0;
        while ([rs next]) {
            v = [rs integerValueForColumnIndex:0];
        }
        XCTAssertEqual(v, 10);
    }
}

- (void)testDatabase {
    {
        ALDatabase *database = [ALDatabase databaseWithPath:kPath keepAlive:YES];

        [database exec:@"DROP TABLE IF EXISTS test_tbl"];
        [database exec:@"CREATE TABLE IF NOT EXISTS test_tbl (int_val INTEGER PRIMARY KEY, d_val REAL, txt_val TEXT, "
                       @"blob_val BLOB, dt_val DATETIME);"];

        NSInteger total = 10000;
        {
            NSString *sql = @"INSERT INTO test_tbl (d_val, txt_val, blob_val, dt_val) VALUES (?, ?, ?, ?)";
            [database cacheStatementForSQL:sql];
            
            [NSThread detachNewThreadWithBlock:^{
                NSLog(@"Thread: %@", [NSThread currentThread]);
                for (int i = 0; i < 10; ++i) {
                    CFTimeInterval t = CFAbsoluteTimeGetCurrent();
                    NSString *txt    = [NSString stringWithFormat:@"time interval: %f", t];
                    NSData *bytes    = [txt dataUsingEncoding:NSUTF8StringEncoding];
                    [database exec:sql args:{t, txt, bytes, [NSDate date]}];
                }
                
                [NSThread detachNewThreadWithBlock:^{
                    NSLog(@"Thread: %@", [NSThread currentThread]);
                    for (int i = 0; i < 10; ++i) {
                        CFTimeInterval t = CFAbsoluteTimeGetCurrent();
                        NSString *txt    = [NSString stringWithFormat:@"time interval: %f", t];
                        NSData *bytes    = [txt dataUsingEncoding:NSUTF8StringEncoding];
                        [database exec:sql args:{t, txt, bytes, [NSDate date]}];
                    }
                }];
            }];

            [[NSRunLoop currentRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:5]];
        
            
            
//            [self measureBlock:^{
////            [database inTransaction:^BOOL{
//                for (int i = 0; i < total; ++i) {
//                    CFTimeInterval t = CFAbsoluteTimeGetCurrent();
//                    NSString *txt    = [NSString stringWithFormat:@"time interval: %f", t];
//                    NSData *bytes    = [txt dataUsingEncoding:NSUTF8StringEncoding];
//                    [database exec:sql args:{t, txt, bytes, [NSDate date]}];
//                }
////                return YES;
////            } eventHandler:nil];
//            
//             }];
        }

//        __block NSInteger count = 0;
//        {
////            [self measureBlock:^{
//                ALDBResultSet *rs = [database query:@"SELECT * FROM test_tbl"];
//                while ([rs next]) {
//                    if (rs[@"blob_val"] && rs[@"dt_val"]) {/* nop */}
//                    ++count;
//                }
////            }];
//        }

//        XCTAssertEqual(total, count);
    }
}

//- (void)testPerformanceExample {
//    // This is an example of a performance test case.
//    [self measureBlock:^{
//        // Put the code you want to measure the time of here.
//    }];
//}

@end
