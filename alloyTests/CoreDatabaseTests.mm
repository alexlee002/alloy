//
//  CoreDatabaseTests.m
//  alloyTests
//
//  Created by Alex Lee on 22/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TestFileModel.h"
#import "ALDBExpr.h"
#import "sql_value.hpp"
#import "ALDBProperty.h"
#import "ALDBResultColumn.h"
#import "ALDBStatement.h"
#import "ALDatabase.h"
#import "NSObject+AL_Database.h"
#import "sql_update.hpp"
#import "sql_insert.hpp"
#import "qualified_table_name.hpp"

@interface CoreDatabaseTests : XCTestCase

@end

@implementation CoreDatabaseTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)reset {
    [[NSFileManager defaultManager] removeItemAtPath:[TestFileModel databaseIdentifier] error:nil];
}

- (void)testSQL {
    [self reset];
    
    ALDatabase *database = [TestFileModel al_database];

    {
        NSError *error;
        XCTAssertTrue([database
             exec:aldb::SQLInsert()
                      .insert(ALTableNameForModel(TestFileModel.class).UTF8String,
                              {ALDB_COL(TestFileModel, fid).UTF8String, ALDB_COL(TestFileModel, fileName).UTF8String,
                               ALDB_COL(TestFileModel, basePath).UTF8String, ALDB_COL(TestFileModel, size).UTF8String,
                               ALDB_COL(TestFileModel, mtime).UTF8String, ALDB_COL(TestFileModel, ctime).UTF8String})
                      .values({122234, "test.jpg", "/path/to/file", 40960, [NSDate date].timeIntervalSince1970,
                               [NSDate date].timeIntervalSinceReferenceDate})
            error:&error]);
    }

    {
        NSError *error;
        std::list<const std::pair<const aldb::UpdateColumns, const ALDBExpr>> updateValues;
        updateValues.push_back({ALDB_PROP(TestFileModel, fileName), "test-name-1111.gif"});
        updateValues.push_back({ALDB_PROP(TestFileModel, mtime), [NSDate date].timeIntervalSince1970});

        XCTAssertTrue([database
             exec:(aldb::SQLUpdate().update(ALTableNameForModel(TestFileModel.class).UTF8String).set(updateValues))
            error:&error]);
    }
}

@end

