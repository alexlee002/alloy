//
//  ActiveRecordTests.m
//  alloy
//
//  Created by Alex Lee on 09/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSObject+AL_Database.h"
#import "ALActiveRecord.h"
#import "ALMacros.h"
#import "YYClassInfo.h"
#import "column_def.hpp"
#import "TestFileModel.h"
#import "ALDatabase.h"
#import "sql_pragma.hpp"
#import "pragma.hpp"
#import "ALDBExpr.h"
#import "NSObject+ALModel.h"

@interface ActiveRecordTests : XCTestCase

@end

@implementation ActiveRecordTests

- (void)setUp {
    [super setUp];
}

- (void)reset {
    [[NSFileManager defaultManager] removeItemAtPath:[TestFileModel databaseIdentifier] error:nil];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testDBInit {
    [self reset];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 10;
    
    NSInteger count = 20;
    NSMutableArray *tasks = [NSMutableArray array];
    for (int i = 0; i < count; ++i) {
        [tasks addObject:[NSBlockOperation blockOperationWithBlock:^{
            ALDatabase *db = [ALDatabase databaseWithPath:[TestFileModel databaseIdentifier] keepAlive:YES];
            if (i % 2 == 0) {
                [db exec:aldb::SQLPragma().pragma(aldb::Pragma::TABLE_INFO, "test_1") error:nil];
            } else {
                [db exec:aldb::SQLPragma().pragma(aldb::Pragma::USER_VERSION) error:nil];
            }
            NSLog(@"== %d: done!", i);
        }]];
    }
    
    [queue addOperations:tasks waitUntilFinished:YES];
    
    NSLog(@"Done!");
}

- (void)testActiveRecord {
    [self reset];
    
    TestFileModel *file = [[TestFileModel alloc] init];
    file.fid = 1234567;
    file.size = 24680;
    file.fileName = @"test.png";
    file.basePath = @"/test/path";
    file.ctime = [NSDate dateWithTimeIntervalSinceNow:-864000.f];
    file.mtime = [NSDate date];
    
    {
        // insert
        XCTAssertTrue([file al_saveOrReplace:YES]);
    }
    
    {
        // select
        XCTAssertEqual([TestFileModel al_modelsCountInCondition:1], 1);
        
        TestFileModel *firstFile = [TestFileModel al_modelEnumeratorInCondition:1].nextObject;
        NSLog(@"%@", [firstFile al_modelDescription]);
        
        firstFile = (TestFileModel *)[TestFileModel al_modelWithRowId:1];
    }
    {
        // update
        TestFileModel *firstFile = [TestFileModel al_modelEnumeratorInCondition:1].nextObject;
        firstFile.fileName = @"test-1.jpg";
        XCTAssertTrue([firstFile al_updateOrReplace:YES]);
        
        TestFileModel *nextFile = [TestFileModel al_modelEnumeratorInCondition:1].nextObject;
        XCTAssertEqualObjects(nextFile.fileName, firstFile.fileName);

        XCTAssertTrue([TestFileModel al_updateProperties:@{ ALDB_COL(TestFileModel, size): @20480 }
                                           withCondition:ALDB_PROP(TestFileModel, fid) == 1234567
                                                 replace:YES]);
        nextFile = [TestFileModel al_modelEnumeratorInCondition:1].nextObject;
        XCTAssertEqual(nextFile.size, 20480);
    }
    {
        //delete
        TestFileModel *firstFile = [TestFileModel al_modelEnumeratorInCondition:1].nextObject;
        [firstFile al_deleteModel];
    }
}

@end
