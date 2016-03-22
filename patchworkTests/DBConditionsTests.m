//
//  DBConditionsTests.m
//  patchwork
//
//  Created by Alex Lee on 3/21/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ALSQLCondition.h"

@interface DBConditionsTests : XCTestCase

@end

@implementation DBConditionsTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSimleConditions {
    ALSQLCondition *condition = EQ(@"col2", @4).AND(GT(@"col3", @4)).AND(EQ(@"col1", @"s")).build;
    XCTAssert([condition isKindOfClass:[ALSQLCondition class]]);
    NSLog(@"condition: %@", condition);
    XCTAssertEqualObjects(condition.sqlClause, @"(col2 = ?) AND (col3 > ?) AND (col1 = ?)");
}

- (void)testNestedConditions {
    ALSQLCondition *condition = EQ(@"col", @1).AND(EQ(@"col2", @1).OR(EQ(@"col2", @2)).OR(EQ(@"col2", @3))).AND(GT(@"col3", @3));
    NSLog(@"condition: %@", condition);
    XCTAssertEqualObjects(condition.sqlClause, @"(col = ?) AND ((col2 = ?) OR (col2 = ?) OR (col2 = ?)) AND (col3 > ?)");
}

- (void)testConditionArray {
    ALSQLCondition *condition = AND(@[EQ(@"col1", @1), EQ(@"col2", @1), EQ(@"col3", @1), EQ(@"col4", @1)]);
    NSLog(@"condition: %@", condition);
    XCTAssertEqualObjects(condition.sqlClause, @"(col1 = ?) AND (col2 = ?) AND (col3 = ?) AND (col4 = ?)");
    
    condition = AND(@[EQ(@"col1", @1), EQ(@"col2", @1), EQ(@"col3", @1)]);
    XCTAssertEqualObjects(condition.sqlClause, @"(col1 = ?) AND (col2 = ?) AND (col3 = ?)");
    
    condition = OR(@[BIT_AND(@"col1", @1), EQ(@"col2", @1)]);
    XCTAssertEqualObjects(condition.sqlClause, @"((col1 & 1) OR (col2 = ?))");
    
    condition = AND(@[EQ(@"col1", @1), IS_NULL(@"col2"), NOT(BIT_OR(@"col3", @3))]);
    XCTAssertEqualObjects(condition.sqlClause, @"(col1 = ?) AND (col2 IS NULL) AND (! col3 | 3)");
}

- (void)testNestedArray {
    ALSQLCondition *condition = OR(@[EQ(@"col1", @1), EQ(@"col2", @1)]).AND(OR(@[ EQ(@"colA", @1), EQ(@"colB", @1) ]));
    NSLog(@"condition: %@", condition);
    XCTAssertEqualObjects(condition.sqlClause, @"((col1 = ?) OR (col2 = ?)) AND ((colA = ?) OR (colB = ?))");
}

- (void)testSQLExpression {
    ALSQLCondition *condition = EQ(@"col1", AS_EXP(@"col2"));
    NSLog(@"condition: %@", condition);
    XCTAssertEqualObjects(condition.sqlClause, @"(col1 = col2)");

    NSString *str = BIT_AND(@"col1", @1).stringify;
    XCTAssertEqualObjects(str, @"col1 & 1");
    
    str = EXP_OP(@"col1", @"||", @"abc").stringify;
    XCTAssertEqualObjects(str, @"col1 || abc");
    
    str = EQ(BIT_OR(@"col1", @2).stringify, @2).sqlClause;
    XCTAssertEqualObjects(str, @"(col1 | 2 = ?)");
    
}

- (void)testInExp {
    ALSQLCondition *condition = IN(@"col", @[@1, @2, @3, @4, @5]);
    NSLog(@"condition: %@", condition);
    XCTAssertEqualObjects(condition.sqlClause, @"(col IN [?, ?, ?, ?, ?])");
}

- (void)testNextedInExp {
    ALSQLCondition *condition = IN(@"col", @[@1, @2, @3]).AND(NGT(@"col2", @6));
    NSLog(@"condition: %@", condition);
    XCTAssertEqualObjects(condition.sqlClause, @"(col IN [?, ?, ?]) AND (col2 <= ?)");
}

- (void)testLikeExp {
    ALSQLCondition *condition = LIKE(@"col", @"aaa_bbb");
    NSLog(@"condition: %@", condition);
    XCTAssertEqualObjects(condition.sqlClause, @"(col LIKE ?)");
    XCTAssertEqualObjects(condition.sqlArguments, @[@"aaa_bbb"]);
    
    condition = LIKE(@"col", @"aaa%sss");
    NSLog(@"condition: %@", condition);
    XCTAssertEqualObjects(condition.sqlClause, @"(col LIKE ?)");
    XCTAssertEqualObjects(condition.sqlArguments, @[@"aaa%sss"]);
}


- (void)testLikeExp1 {
    ALSQLCondition *condition = MATCHS_SUBFIX(@"col", @22, matchsAny);
    NSLog(@"condition: %@", condition);
    XCTAssertEqualObjects(condition.sqlClause, @"(col LIKE ?)");
    XCTAssertEqualObjects(condition.sqlArguments, @[@"%22"]);
    
    condition = MATCHS_SUBFIX(@"col", @22, 3);
    NSLog(@"condition: %@", condition);
    XCTAssertEqualObjects(condition.sqlClause, @"(col LIKE ?)");
    XCTAssertEqualObjects(condition.sqlArguments, @[@"___22"]);
    
    
    condition = MATCHS_PREFIX(@"col", @22, matchsAny);
    NSLog(@"condition: %@", condition);
    XCTAssertEqualObjects(condition.sqlClause, @"(col LIKE ?)");
    XCTAssertEqualObjects(condition.sqlArguments, @[@"22%"]);
    
    condition = MATCHS_PREFIX(@"col", @22, 2);
    NSLog(@"condition: %@", condition);
    XCTAssertEqualObjects(condition.sqlClause, @"(col LIKE ?)");
    XCTAssertEqualObjects(condition.sqlArguments, @[@"22__"]);
}

@end
