//
//  ALSQLClauseTests.m
//  patchwork
//
//  Created by 吴晓龙 on 16/10/13.
//  Copyright © 2016年 Alex Lee. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ALSQLClause.h"
#import "ALSQLClause+SQLOperation.h"
#import "SafeBlocksChain.h"
#import "ALSQLClause+SQLFunctions.h"

@interface ALSQLClauseTests : XCTestCase

@end

@implementation ALSQLClauseTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}


#pragma mark - sql func test
- (void)testSQLFunc1 {
    ALSQLClause *sql = sqlFunc(@"length", @"column_name", nil);
    XCTAssertEqualObjects(sql.SQLString, @"LENGTH(column_name)");
}

- (void)testSQLFunc2 {
    ALSQLClause *sql = sqlFunc(@"substr", @"column_name", @5, nil);
    XCTAssertEqualObjects(sql.SQLString, @"SUBSTR(column_name, 5)");
}

- (void)testSQLFunc3 {
    NSArray *values  = @[ @"/", @"//" ];
    ALSQLClause *sql = sqlFunc(
        @"length",
        SafeBlocksChainObj(sqlFunc(@"replace", @"col_name", @"?", @"?", nil), ALSQLClause).SET_ARG_VALUES(values), nil);
    XCTAssertEqualObjects(sql.SQLString, @"LENGTH(REPLACE(col_name, ?, ?))");
    XCTAssertEqualObjects(sql.argValues, values);
}

- (void)testSQLFuncABS {
    XCTAssertEqualObjects(SQL_ABS(@"col1").SQLString, @"ABS(col1)");
    XCTAssertEqualObjects(SQL_ABS(@1).SQLString, @"ABS(1)");
    XCTAssertEqualObjects(SQL_ABS([@"col1" toSQL]).SQLString, @"ABS(col1)");
}

- (void)testSQLFunc4 {
    XCTAssertEqualObjects(SQL_MAX(@[@"col1", @"col2", @"col3"]).SQLString, @"MAX(col1, col2, col3)");
    XCTAssertEqualObjects(SQL_MIN(@[[@"?, ?, ?" toSQLWithArgValues:@[@2, @1, @3]]]).SQLString, @"MIN(?, ?, ?)");
}


#pragma mark - sql operation test
- (void)testAND {
    ALSQLClause *sql = [@"col1 = 1" toSQL].AND([@"col2 = '123'" toSQL]);
    XCTAssertEqualObjects(sql.SQLString, @"col1 = 1 AND col2 = '123'");
    
    sql = @"col1".EQ(@1).AND(@"col2".HAS_PREFIX(@"abc"));
    NSArray *values = @[@1, @"abc%"];
    
    XCTAssertEqualObjects(sql.SQLString, @"col1 = ? AND col2 LIKE ?");
    XCTAssertEqualObjects(sql.argValues, values);
}

- (void)testAND1 {
    ALSQLClause *sql = @"col1".NEQ(@1).OR(@"col1".NEQ(@2)).AND(@"col2".EQ(@0).OR(@"col2".GT(@100)));
    XCTAssertEqualObjects(sql.SQLString, @"(col1 != ? OR col1 != ?) AND (col2 = ? OR col2 > ?)");
}

- (void)testCaseWhen {
    ALSQLClause *sql = [@"" toSQL]
                           .CASE(@"col1")
                           .WHEN(@0)
                           .THEN([@"zero" SQLFromArgValue])
                           .WHEN(@1)
                           .THEN([@"one" SQLFromArgValue])
                           .ELSE([@"others" SQLFromArgValue])
                           .END();
    XCTAssertEqualObjects(sql.SQLString, @" CASE col1 WHEN ? THEN ? WHEN ? THEN ? ELSE ? END");
    
    NSArray *values = @[@0, @"zero", @1, @"one", @"others"];
    XCTAssertEqualObjects(sql.argValues, values);
}

@end
