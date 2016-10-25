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
- (void)testSQLFunc {
    // sql function without argument
    ALSQLClause *sql = sqlFunc(@"length", @"column_name", nil);
    XCTAssertEqualObjects(sql.SQLString, @"LENGTH(column_name)");
    
    // sql function with arguments
    sql = sqlFunc(@"substr", @"column_name", @5, nil);
    XCTAssertEqualObjects(sql.SQLString, @"SUBSTR(column_name, 5)");

    // complex function and arguments
    NSArray *values = @[ @"/", @"//" ];
    sql = sqlFunc(
        @"length",
        SafeBlocksChainObj(sqlFunc(@"replace", @"col_name", @"?", @"?", nil), ALSQLClause).SET_ARG_VALUES(values), nil);
    XCTAssertEqualObjects(sql.SQLString, @"LENGTH(REPLACE(col_name, ?, ?))");
    XCTAssertEqualObjects(sql.argValues, values);
    
    XCTAssertEqualObjects(sqlFunc(@"replace", @"col_name", [@5 SQLFromArgValue], [@3 SQLFromArgValue], nil).SQLString,
                          @"REPLACE(col_name, ?, ?)");
}

- (void)testSQLInnerFuncs {
    XCTAssertEqualObjects(SQL_MAX(@[ @"col1", @"col2", @"col3" ]).SQLString, @"MAX(col1, col2, col3)");
    XCTAssertEqualObjects(SQL_MIN(@[ [@"?, ?, ?" toSQLWithArgValues:@[ @2, @1, @3 ]] ]).SQLString, @"MIN(?, ?, ?)");
    XCTAssertEqualObjects(SQL_MIN(@[ [@1 SQLFromArgValue], [@3 SQLFromArgValue], [@2 SQLFromArgValue] ]).SQLString,
                          @"MIN(?, ?, ?)");

    XCTAssertEqualObjects(SQL_ABS(@"col1").SQLString, @"ABS(col1)");
    XCTAssertEqualObjects(SQL_ABS(@1).SQLString, @"ABS(1)");
    XCTAssertEqualObjects(SQL_ABS([@"col1" toSQL]).SQLString, @"ABS(col1)");
}




#pragma mark - sql operation test
- (void)testAND {
    ALSQLClause *sql = [@"col1 = 1" toSQL].AND([@"col2 = '123'" toSQL]);
    XCTAssertEqualObjects(sql.SQLString, @"col1 = 1 AND col2 = '123'");
    
    sql = @"col1".EQ(@1).AND(@"col2".HAS_PREFIX(@"abc"));
    NSArray *values = @[@1, @"abc%"];
    XCTAssertEqualObjects(sql.SQLString, @"col1 = ? AND col2 LIKE ?");
    XCTAssertEqualObjects(sql.argValues, values);
    
    sql = @"col1".NEQ(@1).OR(@"col1".NEQ(@2)).AND(@"col2".EQ(@0).OR(@"col2".GT(@100)));
    XCTAssertEqualObjects(sql.SQLString, @"(col1 != ? OR col1 != ?) AND (col2 = ? OR col2 > ?)");
}


- (void)testIN {
    XCTAssertEqualObjects((@"col1".IN(@[@1, @2, @3])).SQLString, @"col1 IN (?, ?, ?)");
    XCTAssertEqualObjects((@"col1".IN(@"SELECT col FROM table")).SQLString, @"col1 IN (SELECT col FROM table)");
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
    XCTAssertEqualObjects(sql.SQLString, @"CASE col1 WHEN ? THEN ? WHEN ? THEN ? ELSE ? END");
    
    NSArray *values = @[@0, @"zero", @1, @"one", @"others"];
    XCTAssertEqualObjects(sql.argValues, values);
}

@end
