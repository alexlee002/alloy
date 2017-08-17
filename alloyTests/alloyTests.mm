//
//  alloyTests.m
//  alloyTests
//
//  Created by Alex Lee on 13/07/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <XCTest/XCTest.h>
#include "sql_expr.hpp"
#include "column.hpp"
#include "aldb.h"
#include "database.hpp"
#include "handle.hpp"
#include "handle_recyclable.hpp"
#include "handle_pool.hpp"
#include "statement_handle.hpp"
#include <sqlite3.h>
#import "ALSQLValue.h"

@interface alloyTests : XCTestCase

@end

@implementation alloyTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)testSQLExpr {
    
    aldb::SQLClause clause("select * from table where col_1=? and col_2=?", {"12", ALSQLValue(@"abc")});
    NSLog(@"%s", clause.debug_description().c_str());
    
    
    aldb::Column col("col1");
    aldb::SQLExpr expr(col);
    expr = expr > 1 && (expr == 1 || expr == 2);
    XCTAssertEqual("col1 > ? AND (col1 = ? OR col1 = ?)", expr.sql_str());
}

- (void)testCustomSQLFunc {
    aldb::Database database = aldb::Database("/Users/alexlee/Desktop/aldb-test.db", {}, [](const aldb::RecyclableHandle &handle) -> bool {
        handle->register_custom_sql_function("NOW", 0, [](void *ctx, int argc, void **argv)->void {
            sqlite3_result_int64((sqlite3_context *)ctx , time(nullptr));
        });
        
        return true;
    });
    
    std::shared_ptr<aldb::StatementHandle> stmt = database.prepare("SELECT NOW()");
    if (stmt && stmt->step()) {
        NSLog(@"%ld", (long)(stmt->get_int64_value(0)));
    }
}

//- (void)tearDown {
//    // Put teardown code here. This method is called after the invocation of each test method in the class.
//    [super tearDown];
//}
//
//- (void)testExample {
//    // This is an example of a functional test case.
//    // Use XCTAssert and related functions to verify your tests produce the correct results.
//}
//
//- (void)testPerformanceExample {
//    // This is an example of a performance test case.
//    [self measureBlock:^{
//        // Put the code you want to measure the time of here.
//    }];
//}

@end
