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
#import "ALSQLSelectStatement.h"

@interface ALSQLClauseTests : XCTestCase

@end

@implementation ALSQLClauseTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}


#pragma mark - sql func test
- (void)testSQLFunc {
    ALSQLClause *sql = SQLFunc(@"length", @[@"column_name"]);
    XCTAssertEqualObjects(sql.SQLString, @"LENGTH(column_name)");
    
    sql = SQLFunc(@"substr", @[ @"column_name", @5]);
    XCTAssertEqualObjects(sql.SQLString, @"SUBSTR(column_name, 5)");

    // complex function and arguments
    NSArray *values = @[ @"/", @"//" ];
    sql = SQLFunc(
        @"length",
        @[SQLFunc(@"replace", @[@"col_name", @"?", @"?" ]).SET_ARG_VALUES(values)]);
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
- (void)testSQLClause {
    
    ALSQLClause *sql = [@"col1 = 1" al_SQLClause].SQL_AND([@"col2 = '123'" al_SQLClause]);
    XCTAssertEqualObjects(sql.SQLString, @"col1 = 1 AND col2 = '123'");
    
    
    XCTAssertEqualObjects(@"col1".SQL_EQ(@1).SQL_NOT().SQLString, @"NOT (col1 = ?)");
    sql = sql_op_left(@"~", @"col1".SQL_EQ(@1));
    XCTAssertEqualObjects(sql.SQLString, @"~(col1 = ?)");
    sql = sql_op_left(@"-", [@"col1" al_SQLClause]).SQL_EQ(@1).SQL_OR(@"col1".SQL_GT(@2));
    XCTAssertEqualObjects(sql.SQLString, @"-(col1) = ? OR col1 > ?");
    
    
    sql = @"col1".SQL_EQ(@1).SQL_AND(@"col2".SQL_PREFIX_LIKE(@"abc"));
    NSArray *values = @[@1, @"abc%"];
    XCTAssertEqualObjects(sql.SQLString, @"col1 = ? AND col2 LIKE ?");
    XCTAssertEqualObjects(sql.argValues, values);
  
    sql = @"col1".SQL_EQ(@"abc").SQL_COLLATE(@"nocase").SQL_AND(@"col2".SQL_LIKE(@"abc\\_").SQL_ESCAPE(@"\\"));
    XCTAssertEqualObjects(sql.SQLString, @"col1 = ? COLLATE nocase AND col2 LIKE ? ESCAPE ?");
    
    sql = @"col1".SQL_EQ(@1).SQL_AND(@"col2".SQL_PREFIX_LIKE(@"abc").SQL_NOT());
    XCTAssertEqualObjects(sql.SQLString, @"col1 = ? AND NOT (col2 LIKE ?)");
    
    sql = @"col1".SQL_NEQ(@1).SQL_OR(@"col1".SQL_NEQ(@2)).SQL_AND(@"col2".SQL_EQ(@0).SQL_OR(@"col2".SQL_GT(@100)));
    XCTAssertEqualObjects(sql.SQLString, @"(col1 != ? OR col1 != ?) AND (col2 = ? OR col2 > ?)");
    
    sql = @"col1".SQL_EQ(@1).SQL_AND(@"col1".SQL_NEQ(@2).SQL_OR(@"col2".SQL_EQ(@0).SQL_AND(@"col2".SQL_GT(@100))));
    XCTAssertEqualObjects(sql.SQLString, @"col1 = ? AND (col1 != ? OR col2 = ? AND col2 > ?)");
    
    XCTAssertEqualObjects(@"col1".SQL_ISNULL().SQLString, @"col1 IS NULL");
    ALSQLSelectStatement *select = [[ALSQLSelectStatement alloc] init];
    sql = select.SELECT(@[@"col1"]).FROM(@"table").WHERE(@"col2=?").SQL_ISNULL();
    XCTAssertEqualObjects(sql.SQLString,
                          @"(SELECT col1 FROM table WHERE col2=?) IS NULL");
    
    XCTAssertEqualObjects(@"col1".SQL_GT(@2).SQL_ISNULL().SQLString, @"col1 > ? IS NULL");
    
    XCTAssertEqualObjects(@"col1".SQL_IS(@"abc").SQLString, @"col1 IS ?");
    
    sql = @"col1".SQL_BETWEEN(@1, @2);
    XCTAssertEqualObjects(sql.SQLString, @"col1 BETWEEN ? AND ?");
    sql = SQL_LENGTH(@"col1").SQL_BETWEEN(@1, @100);
    XCTAssertEqualObjects(sql.SQLString, @"LENGTH(col1) BETWEEN ? AND ?");
    sql = @"col1".SQL_BETWEEN([ALSQLSelectStatement statement].SELECT(@[[@1 al_SQLClauseByUsingAsArgValue]]), @20);
    XCTAssertEqualObjects(sql.SQLString, @"col1 BETWEEN (SELECT ?) AND ?");
    
    sql = [[ALSQLClause sql_case:@"col1" when:[ALSQLSelectStatement statement].SELECT(@[@"'aa'"]) then:[@"NULL" al_SQLClause]  else:@"123"] sql_case_end];
    XCTAssertEqualObjects(sql.SQLString, @"CASE col1 WHEN (SELECT 'aa') THEN NULL ELSE ? END");
}


- (void)testIN {
    XCTAssertEqualObjects((@"col1".SQL_IN(@[@1, @2, @3])).SQLString, @"col1 IN (?, ?, ?)");
    XCTAssertEqualObjects((@"col1".SQL_IN(@"SELECT col FROM table")).SQLString, @"col1 IN (SELECT col FROM table)");
    
    ALSQLClause *sql = @"col1".SQL_IN([ALSQLSelectStatement statement].SELECT(nil).FROM(@"table"));
    XCTAssertEqualObjects(sql.SQLString, @"col1 IN (SELECT * FROM table)");
}


@end
