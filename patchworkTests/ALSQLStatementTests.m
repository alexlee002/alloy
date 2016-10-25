//
//  ALSQLStatementTests.m
//  patchwork
//
//  Created by Alex Lee on 25/10/2016.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ALSQLSelectStatement.h"
#import "ALSQLInsertStatement.h"
#import "ALSQLUpdateStatement.h"
#import "ALSQLDeleteStatement.h"
#import "ALSQLClause+SQLOperation.h"
#import "ALSQLClause+SQLFunctions.h"
#import "SafeBlocksChain.h"
#import "ALDatabase.h"

@interface ALSQLStatementTests : XCTestCase

@end

@implementation ALSQLStatementTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)testSelectStmt {
    ALDatabase *db = [ALDatabase databaseWithPath:@""];
    
    // simple query
    ALSQLSelectStatement *stmt = [ALSQLSelectStatement statementWithDatabase:db];
    stmt.SELECT(nil).FROM(@"test").WHERE(@"name".EQ(@"alex"));
    XCTAssertEqualObjects(stmt.SQLString, @"SELECT * FROM test WHERE name = ?");
    NSArray *values = @[@"alex"];
    XCTAssertEqualObjects(stmt.argValues, values);
    
    // specify multi-column names
    stmt = [ALSQLSelectStatement statementWithDatabase:db];
    stmt.SELECT(@[@"rowid", @"*"]).FROM(@"test NOT INDEXED");
    XCTAssertEqualObjects(stmt.SQLString, @"SELECT rowid, * FROM test NOT INDEXED");
    
    // multi-table query
    stmt = [ALSQLSelectStatement statementWithDatabase:db];
    stmt.SELECT(nil).FROM(@[@"table1", @"table2"]).WHERE([@"table1.id = table2.id" toSQL]);
    XCTAssertEqualObjects(stmt.SQLString, @"SELECT * FROM table1, table2 WHERE table1.id = table2.id");
    
    // JOIN query (raw string)
    stmt = [ALSQLSelectStatement statementWithDatabase:db];
    stmt.SELECT(nil).FROM(@"table1 LEFT JOIN table2 ON table1.id = table2.id");
    XCTAssertEqualObjects(stmt.SQLString, @"SELECT * FROM table1 LEFT JOIN table2 ON table1.id = table2.id");
    
    // JOIN query (using ALSQLClause)
    stmt = [ALSQLSelectStatement statementWithDatabase:db];
    stmt.SELECT(nil).FROM([@"table1 LEFT JOIN table2 ON table1.id = ? AND table2.id = ?" toSQLWithArgValues:@[@"abc", @"123"]]);
    XCTAssertEqualObjects(stmt.SQLString, @"SELECT * FROM table1 LEFT JOIN table2 ON table1.id = ? AND table2.id = ?");
    
    
    // complete select-core statement
    stmt = [ALSQLSelectStatement statementWithDatabase:db];
    stmt.SELECT(@[@"COUNT(*) AS num", SQL_UPPER(@"province_code")])
        .FROM(@"students_info")
        .WHERE(SQL_LOWER(@"gender").EQ(@"female"))
        .HAVING(@"age".GT(@18))
        .ORDER_BY(@"num".DESC())
        .ORDER_BY(@"province_code")
        .LIMIT(@5)
        .OFFSET(@3);
    NSLog(@"SQL: %@", stmt.SQLString);
    XCTAssertEqualObjects(stmt.SQLString,
                          @"SELECT COUNT(*) AS num, UPPER(province_code) FROM students_info WHERE LOWER(gender) = ? HAVING age > ? ORDER BY num DESC, province_code LIMIT 5 OFFSET 3");
    
    
    
    // test nil-object-blocks-chain
    // RECOMMEND: using 'SafeBlocksChainObj' macro to wrapper the first object that invoking a block;
    stmt = SafeBlocksChainObj(nil, ALSQLSelectStatement);
    stmt.SELECT(nil).FROM(@"test").WHERE(@"name".EQ(@"alex"));
    XCTAssertNil(stmt.SQLString);
    XCTAssertNil(stmt.argValues);
    XCTAssertNil(stmt.toSQL);
}

- (void)testInsertStmt {
    ALDatabase *db = [ALDatabase databaseWithPath:@""];
    
    // insert using values, we can repeat calling 'VALUES' multiple times to insert multiple rows
    NSArray *u1 = @[@"alex", @30, @"male", @"BJ/CN"];
    NSArray *u2 = @[@"Jim", @"18", @"male", @"SF/US"];
    ALSQLInsertStatement *stmt = [ALSQLInsertStatement statementWithDatabase:db];
    stmt.INSERT()
        .OR_REPLACE(YES)
        .INTO(@"users")
        .COLUMNS(@[@"name", @"age", @"gender", @"address"])
        .VALUES(u1)
        .VALUES(u2);
    XCTAssertEqualObjects(stmt.SQLString,
                          @"INSERT OR REPLACE INTO users (name, age, gender, address) VALUES (?, ?, ?, ?), (?, ?, ?, ?)");
    NSArray *values = [u1 arrayByAddingObjectsFromArray:u2];
    XCTAssertEqualObjects(stmt.argValues, values);
    
    // insert using values dictionary: insert only a row
    stmt = [ALSQLInsertStatement statementWithDatabase:db];
    NSDictionary *dict = @{@"name": @"Roger", @"age": @34, @"gender": @"male", @"address": @"AB/CA"};
    stmt.INSERT().INTO(@"users").VALUES_DICT(dict);
    NSArray *keys = dict.allKeys;
    NSString *sql = [NSString stringWithFormat:@"INSERT INTO users (%@) VALUES (?, ?, ?, ?)",
                     [keys componentsJoinedByString:@", "]];
    values = [dict objectsForKeys:keys notFoundMarker:NSNull.null];
    XCTAssertEqualObjects(stmt.SQLString, sql);
    XCTAssertEqualObjects(stmt.argValues, values);
    
    // insert using selection results
    stmt = [ALSQLInsertStatement statementWithDatabase:db];
    stmt.INSERT().INTO(@"users")
        .SELECT_STMT([ALSQLSelectStatement statementWithDatabase:db].SELECT(nil)
                        .FROM(@"tmp_users")
                        .WHERE(@"status".NEQ(@0))
                     .toSQL);
    XCTAssertEqualObjects(stmt.SQLString, @"INSERT INTO users SELECT * FROM tmp_users WHERE status != ?");
    values = @[@0];
    XCTAssertEqualObjects(stmt.argValues, values);
    
}

- (void)testUpdateStmt {
    ALDatabase *db = [ALDatabase databaseWithPath:@""];
    
    ALSQLUpdateStatement *stmt = [ALSQLUpdateStatement statementWithDatabase:db];
    stmt.UPDATE(@"users")
        .OR_REPLACE(YES)
        .SET(@{@"age": @30})    // NSDictionary
        .SET(@"gender".EQ(@"female"))   // ALSQLClause
        .SET(@[@"name".EQ(@"sindy"), @"address".EQ(@"AB/CA")]) // NSArray<ALSQLClause *>
        .WHERE(@"name".EQ(@"Roger"));
    XCTAssertEqualObjects(stmt.SQLString, @"UPDATE OR REPLACE users SET age = ?, gender = ?, name = ?, address = ? WHERE name = ?");
    NSArray *values = @[@30, @"female", @"sindy", @"AB/CA", @"Roger"];
    XCTAssertEqualObjects(stmt.argValues, values);
}

- (void)testDeleteStmt {
    ALDatabase *db = [ALDatabase databaseWithPath:@""];
    
    ALSQLDeleteStatement *stmt = [ALSQLDeleteStatement statementWithDatabase:db];
    stmt.DELETE().FROM(@"users").WHERE(@1);
    XCTAssertEqualObjects(stmt.SQLString, @"DELETE FROM users WHERE 1");
    
    stmt = [ALSQLDeleteStatement statementWithDatabase:db];
    stmt.DELETE().FROM(@"users").WHERE(@"name".HAS_SUBFIX(@"lee")).ORDER_BY(@"age".DESC()).LIMIT(@5);
    XCTAssertEqualObjects(stmt.SQLString, @"DELETE FROM users WHERE name LIKE ? ORDER BY age DESC LIMIT 5");
}

@end
