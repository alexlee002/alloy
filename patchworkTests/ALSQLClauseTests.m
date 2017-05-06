//
//  ALSQLClauseTests.m
//  patchwork
//
//  Created by Alex Lee on 16/10/13.
//  Copyright © 2016- Alex Lee. All rights reserved.
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
    ALSQLClause *sql = SQLFunc(@"length", @[@"column_name"]);
    XCTAssertEqualObjects(sql.SQLString, @"LENGTH(column_name)");
    
    // sql function with arguments
    sql = SQLFunc(@"substr", @[ @"column_name", @5]);
    XCTAssertEqualObjects(sql.SQLString, @"SUBSTR(column_name, 5)");

    // complex function and arguments
    NSArray *values = @[ @"/", @"//" ];
    sql = SQLFunc(
        @"length",
        @[al_safeBlocksChainObj(SQLFunc(@"replace", @[@"col_name", @"?", @"?" ]), ALSQLClause).SET_ARG_VALUES(values)]);
    XCTAssertEqualObjects(sql.SQLString, @"LENGTH(REPLACE(col_name, ?, ?))");
    XCTAssertEqualObjects(sql.argValues, values);
    
    XCTAssertEqualObjects(SQLFunc(@"replace", @[@"col_name", [@5 al_SQLClauseByUsingAsArgValue], [@3 al_SQLClauseByUsingAsArgValue]]).SQLString,
                          @"REPLACE(col_name, ?, ?)");
}

- (void)testSQLInnerFuncs {
    XCTAssertEqualObjects(SQL_MAX(@[ @"col1", @"col2", @"col3" ]).SQLString, @"MAX(col1, col2, col3)");
    XCTAssertEqualObjects(SQL_MIN(@[ [@"?, ?, ?" al_SQLClauseWithArgValues:@[ @2, @1, @3 ]] ]).SQLString, @"MIN(?, ?, ?)");
    XCTAssertEqualObjects(SQL_MIN(@[ [@1 al_SQLClauseByUsingAsArgValue], [@3 al_SQLClauseByUsingAsArgValue], [@2 al_SQLClauseByUsingAsArgValue] ]).SQLString,
                          @"MIN(?, ?, ?)");

    XCTAssertEqualObjects(SQL_ABS(@"col1").SQLString, @"ABS(col1)");
    XCTAssertEqualObjects(SQL_ABS(@1).SQLString, @"ABS(1)");
    XCTAssertEqualObjects(SQL_ABS([@"col1" al_SQLClause]).SQLString, @"ABS(col1)");
}




#pragma mark - sql operation test
- (void)testAND {
    ALSQLClause *sql = [@"col1 = 1" al_SQLClause].SQL_AND([@"col2 = '123'" al_SQLClause]);
    XCTAssertEqualObjects(sql.SQLString, @"col1 = 1 AND col2 = '123'");
    
    sql = @"col1".SQL_EQ(@1).SQL_AND(@"col2".SQL_PREFIX_LIKE(@"abc"));
    NSArray *values = @[@1, @"abc%"];
    XCTAssertEqualObjects(sql.SQLString, @"col1 = ? AND col2 LIKE ?");
    XCTAssertEqualObjects(sql.argValues, values);
    
    sql = @"col1".SQL_NEQ(@1).SQL_OR(@"col1".SQL_NEQ(@2)).SQL_AND(@"col2".SQL_EQ(@0).SQL_OR(@"col2".SQL_GT(@100)));
    XCTAssertEqualObjects(sql.SQLString, @"(col1 != ? OR col1 != ?) AND (col2 = ? OR col2 > ?)");
    
//    sql = @"col1".EQ(@"11")
}


- (void)testIN {
    XCTAssertEqualObjects((@"col1".SQL_IN(@[@1, @2, @3])).SQLString, @"col1 IN (?, ?, ?)");
    XCTAssertEqualObjects((@"col1".SQL_IN(@"SELECT col FROM table")).SQLString, @"col1 IN (SELECT col FROM table)");
}

- (void)testCaseWhen {
//    ALSQLClause *sql = [@"" al_SQLClause]
//                           .CASE(@"col1")
//                           .WHEN(@0)
//                           .THEN([@"zero" al_SQLClauseByUsingAsArgValue])
//                           .WHEN(@1)
//                           .THEN([@"one" al_SQLClauseByUsingAsArgValue])
//                           .ELSE([@"others" al_SQLClauseByUsingAsArgValue])
//                           .END();
//    XCTAssertEqualObjects(sql.SQLString, @"CASE col1 WHEN ? THEN ? WHEN ? THEN ? ELSE ? END");
//    
//    NSArray *values = @[@0, @"zero", @1, @"one", @"others"];
//    XCTAssertEqualObjects(sql.argValues, values);
}

@end
