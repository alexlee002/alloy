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
#import "ALLogger.h"

@interface ALSQLStatementTests : XCTestCase
@property(nonatomic, strong) ALDatabase *db;
@end

@implementation ALSQLStatementTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _db = [ALDatabase databaseWithPath:kALInMemoryDBPath];

    [_db.queue inDatabase:^(FMDatabase *_Nonnull db) {
        [db executeUpdate:@"CREATE TABLE IF NOT EXISTS students (_id INTEGER PRIMARY KEY, "
                          @"name TEXT, "
                          @"gender INTEGER, "
                          @"age INTEGER, "
                          @"address TEXT, "
                          @"province TEXT"
                          @")"];
        [db executeUpdate:@"CREATE TABLE IF NOT EXISTS courses (_id INTEGER PRIMARY KEY, "
                          @"name TEXT, "
                          @"teacher TEXT, "
                          @"credit INTEGER, "
                          @"hours INTEGER, "
                          @"fee DOUBLE"
                          @")"];
        [db executeUpdate:@"CREATE TABLE IF NOT EXISTS student_courses (_id INTEGER PRIMARY KEY, "
                          @"sid INTEGER, "
                          @"cid INTEGER, "
                          @"update_time DATETIME"
                          @")"];
    }];
}

- (void)tearDown {
    _db = nil;
}

- (void)testSelectStmt {
    ALSQLSelectStatement *stmt    = nil;
    ALSQLSelectStatement *subStmt = nil;
    NSArray *values               = nil;

    {
        // simple query
        stmt = [ALSQLSelectStatement statementWithDatabase:self.db];
        stmt.SELECT(nil).FROM(@"students").WHERE(@"name".SQL_EQ(@"alex"));
        XCTAssertEqualObjects(stmt.SQLString, @"SELECT * FROM students WHERE name = ?");
        values = @[ @"alex" ];
        XCTAssertEqualObjects(stmt.argValues, values);
        XCTAssertTrue([stmt validateWitherror:nil]);
    }

    {
        // specify multi-column names
        stmt = [ALSQLSelectStatement statementWithDatabase:self.db];
        stmt.SELECT(@[ @"rowid", @"*" ]).FROM(@"students NOT INDEXED");
        XCTAssertEqualObjects(stmt.SQLString, @"SELECT rowid, * FROM students NOT INDEXED");
        XCTAssertTrue([stmt validateWitherror:nil]);
    }

    {
        // multi-table query
        stmt = [ALSQLSelectStatement statementWithDatabase:self.db];
        stmt.SELECT(nil)
            .FROM(@[ @"students", @"student_courses" ])
            .WHERE([@"students._id = student_courses._id" al_SQLClause]);
        XCTAssertEqualObjects(stmt.SQLString,
                              @"SELECT * FROM students, student_courses WHERE students._id = student_courses._id");
        XCTAssertTrue([stmt validateWitherror:nil]);
    }

    {
        // JOIN query (raw string)
        stmt = [ALSQLSelectStatement statementWithDatabase:self.db];
        stmt.SELECT(nil)
            .FROM(@"students LEFT JOIN student_courses ON students._id = student_courses._id")
            .WHERE(@"students._id IS NULL");
        XCTAssertEqualObjects(stmt.SQLString, @"SELECT * FROM students LEFT JOIN student_courses ON students._id = "
                                              @"student_courses._id WHERE students._id IS NULL");
        XCTAssertTrue([stmt validateWitherror:nil]);
    }

    {
        // JOIN query (using ALSQLClause)
        stmt = [ALSQLSelectStatement statementWithDatabase:self.db];
        stmt.SELECT(nil).FROM([@"students LEFT JOIN student_courses ON students._id = ? AND student_courses._id = ?"
            al_SQLClauseWithArgValues:@[ @"1234", @"123" ]]);
        XCTAssertEqualObjects(
            stmt.SQLString,
            @"SELECT * FROM students LEFT JOIN student_courses ON students._id = ? AND student_courses._id = ?");
        XCTAssertTrue([stmt validateWitherror:nil]);
    }

    {
        // SubQuery
        stmt    = [ALSQLSelectStatement statementWithDatabase:self.db];
        subStmt = [ALSQLSelectStatement statementWithDatabase:self.db];
        stmt.SELECT(SQL_COUNT(@"*"))
            .FROM(subStmt.SELECT(@[ @"name", @"age" ]).FROM(@"students").WHERE(@"name".SQL_PREFIX_LIKE(@"alex")))
            .WHERE(@"age".SQL_GT(@(30)));
        ALLogInfo(@"%@", stmt.SQLString);
        XCTAssertEqualObjects(stmt.SQLString,
                              @"SELECT COUNT(*) FROM (SELECT name, age FROM students WHERE name LIKE ?) WHERE age > ?");
    }

    {
        // SubQuery (add alias)
        stmt    = [ALSQLSelectStatement statementWithDatabase:self.db];
        subStmt = [ALSQLSelectStatement statementWithDatabase:self.db];
        stmt.SELECT(SQL_COUNT(@"*"))
            .FROM(subStmt.SELECT(@[ @"name", @"age" ])
                      .FROM(@"students")
                      .WHERE(@"name".SQL_PREFIX_LIKE(@"alex"))
                      .SQL_AS(@"sub_tbl"))
            .WHERE(@"age".SQL_GT(@(30)));
        ALLogInfo(@"%@", stmt.SQLString);
        XCTAssertEqualObjects(
            stmt.SQLString,
            @"SELECT COUNT(*) FROM (SELECT name, age FROM students WHERE name LIKE ?) AS sub_tbl WHERE age > ?");
    }

    {
        // complete select-core statement
        stmt = [ALSQLSelectStatement statementWithDatabase:self.db];
        stmt.SELECT(@[ @"COUNT(*) AS num", SQL_UPPER(@"province").SQL_AS(@"province") ])
            .FROM(@"students")
            .WHERE(SQL_LOWER(@"gender").SQL_EQ(@"1"))
            .GROUP_BY(@"province")
            .HAVING(@"age".SQL_GT(@18))
            .ORDER_BY(@"num".SQL_DESC())
            .ORDER_BY(@"province")
            .LIMIT(@5)
            .OFFSET(@3);
        XCTAssertEqualObjects(stmt.SQLString, @"SELECT COUNT(*) AS num, UPPER(province) AS province FROM students "
                                              @"WHERE LOWER(gender) = ? GROUP BY province HAVING age > ? ORDER BY num "
                                              @"DESC, province LIMIT 5 OFFSET 3");
        XCTAssertTrue([stmt validateWitherror:nil]);
    }

    {
        // test nil-object-blocks-chain
        // RECOMMEND: using 'SafeBlocksChainObj' macro to wrapper the first object that invoking a block;
        stmt = al_safeBlocksChainObj(nil, ALSQLSelectStatement);
        stmt.SELECT(nil).FROM(@"test").WHERE(@"name".SQL_EQ(@"alex"));
        XCTAssertNil(stmt.SQLString);
        XCTAssertNil(stmt.argValues);
        XCTAssertNil(stmt.SQLClause);
    }
}

- (void)testInsertStmt {
    ALSQLInsertStatement *stmt = nil;
    NSArray *values = nil;

    {
        // insert using values, we can repeat calling 'VALUES' multiple times to insert multiple rows
        NSArray *u1 = @[ @"alex", @30, @"1", @"BJ/CN" ];
        NSArray *u2 = @[ @"Jim", @"18", @1, @"SF/US" ];
        stmt        = [ALSQLInsertStatement statementWithDatabase:self.db];
        stmt.INSERT()
            .OR_REPLACE(YES)
            .INTO(@"students")
            .COLUMNS(@[ @"name", @"age", @"gender", @"address" ])
            .VALUES(u1)
            .VALUES(u2);
        XCTAssertEqualObjects(
            stmt.SQLString,
            @"INSERT OR REPLACE INTO students (name, age, gender, address) VALUES (?, ?, ?, ?), (?, ?, ?, ?)");
        values = [u1 arrayByAddingObjectsFromArray:u2];
        XCTAssertEqualObjects(stmt.argValues, values);
        XCTAssertTrue([stmt validateWitherror:nil]);
    }

    {
        // insert using values dictionary: insert only a row
        stmt               = [ALSQLInsertStatement statementWithDatabase:self.db];
        NSDictionary *dict = @{ @"name" : @"Roger", @"age" : @34, @"gender" : @"1", @"address" : @"AB/CA" };
        stmt.INSERT().INTO(@"students").VALUES_DICT(dict);
        NSArray *keys = dict.allKeys;
        NSString *sql = [NSString
            stringWithFormat:@"INSERT INTO students (%@) VALUES (?, ?, ?, ?)", [keys componentsJoinedByString:@", "]];
        values = [dict objectsForKeys:keys notFoundMarker:NSNull.null];
        XCTAssertEqualObjects(stmt.SQLString, sql);
        XCTAssertEqualObjects(stmt.argValues, values);
        XCTAssertTrue([stmt validateWitherror:nil]);
    }

    {
        // insert using selection results
        stmt = [ALSQLInsertStatement statementWithDatabase:self.db];
        stmt.INSERT()
            .INTO(@"students")
            .SELECT_STMT([ALSQLSelectStatement statementWithDatabase:self.db]
                             .SELECT(nil)
                             .FROM(@"students")
                             .WHERE(@"age".SQL_NEQ(@0))
                             .SQLClause);
        XCTAssertEqualObjects(stmt.SQLString, @"INSERT INTO students SELECT * FROM students WHERE age != ?");
        values = @[ @0 ];
        XCTAssertEqualObjects(stmt.argValues, values);
        XCTAssertTrue([stmt validateWitherror:nil]);
    }
}

- (void)testUpdateStmt {
    
    ALSQLUpdateStatement *stmt = [ALSQLUpdateStatement statementWithDatabase:self.db];

//    [[[[[[stmt update:@"students"]
//            replace:NO]
//            setInt:30 forColumn:@"age"]
//            setColumns:@[ @"gender" ] values:@"SELECT 'mail'"]
//            setColumnsValue:@{
//                @"name" : @"sindy",
//                @"address",
//                @"AB/CA"
//            }] where:[@"name" sql_eq:@"Roger"]];

    stmt.UPDATE(@"students")
        .OR_REPLACE(YES)
        .SET(@{@"age": @30})    // NSDictionary
        .SET(@"gender".SQL_EQ(@"2"))   // ALSQLClause
        .SET(@[@"name".SQL_EQ(@"sindy"), @"address".SQL_EQ(@"AB/CA")]) // NSArray<ALSQLClause *>
        .WHERE(@"name".SQL_EQ(@"Roger"));
    XCTAssertEqualObjects(stmt.SQLString, @"UPDATE OR REPLACE students SET age = ?, gender = ?, name = ?, address = ? WHERE name = ?");
    NSArray *values = @[@30, @"2", @"sindy", @"AB/CA", @"Roger"];
    XCTAssertEqualObjects(stmt.argValues, values);
    XCTAssertTrue([stmt validateWitherror:nil]);
}

- (void)testDeleteStmt {
    
    ALSQLDeleteStatement *stmt = [ALSQLDeleteStatement statementWithDatabase:self.db];
    stmt.DELETE().FROM(@"students").WHERE(@1);
    XCTAssertEqualObjects(stmt.SQLString, @"DELETE FROM students WHERE 1");
    XCTAssertTrue([stmt validateWitherror:nil]);
    
    stmt = [ALSQLDeleteStatement statementWithDatabase:self.db];
    stmt.DELETE().FROM(@"students").WHERE(@"name".SQL_SUBFIX_LIKE(@"lee")).ORDER_BY(@"age".SQL_DESC()).LIMIT(@5);
    XCTAssertEqualObjects(stmt.SQLString, @"DELETE FROM students WHERE name LIKE ? ORDER BY age DESC LIMIT 5");
    XCTAssertTrue([stmt validateWitherror:nil]);
}

@end
