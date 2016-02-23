//
//  DBManageTests.m
//  patchwork
//
//  Created by Alex Lee on 2/19/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ALModel+DBManage.h"
#import "UtilitiesHeader.h"
#import "ALDatabase.h"
#import "FMDB.h"
#import "BlocksKit.h"
#import "ALDBColumnInfo.h"
#import "ALSQLSelectCommand.h"
#import "ALSQLInsertCommand.h"
#import "ALSQLUpdateCommand.h"
#import "ALSQLCondition.h"


@interface TestUser : ALModel
@property(nonatomic)        NSInteger Id;
@property(nonatomic, copy)  NSString *name;
@property(nonatomic)        NSInteger age;
@property(nonatomic, copy)  NSString *addr;
@end

@implementation TestUser
@end


@interface TestUser (DBManage)
@end

@implementation TestUser(DBManage)

+ (NSString *)tableName { return @"user"; }
+ (NSUInteger)tableVersion { return 2; }
+ (NSString *)databasePath {
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"test_1.db"];
    return path;
}

+ (nullable NSArray<NSString *> *)primaryKeys {
    return @[ keypathForClass(TestUser, Id) ];
}

+ (nullable NSArray<NSArray<NSString *> *> *)uniqueKeys {
    return @[ keypathForClass(TestUser, name) ];
}

+ (nullable NSArray<NSArray<NSString *> *> *)indexKeys {
    return nil;
}

+ (BOOL)upgradeTableFromVersion:(NSInteger)fromVersion toVerion:(NSInteger)toVersion database:(FMDatabase *)db {
    NSMutableSet *existsCols = [NSMutableSet set];
    FMResultSet *rs = [db executeQuery:[NSString stringWithFormat:@"PRAGMA table_info(%@)", [self tableName]]];
    while ([rs next]) {
        [existsCols addObject:[rs stringForColumn:@"name"]];
    }
    [rs close];
    
    [[[self columnDefines] bk_reject:^BOOL(ALDBColumnInfo *col) {
        return [existsCols containsObject:col.name];
    }] bk_each:^(ALDBColumnInfo *col) {
        NSString *sql = [NSString stringWithFormat:@"ALTER TABLE %@ ADD %@", [self tableName], col.description];
        if (![db executeUpdate:sql]) {
            ALLogError(@"sql: %@\nerror: %@", sql, [db lastError]);
        }
    }];
    
    [self createIndexes:db];
    return YES;
}

@end


@interface DBManageTests : XCTestCase
@end

@implementation DBManageTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)testSetupDB {
    //[[NSFileManager defaultManager] removeItemAtPath:[TestUser databasePath] error:nil];
    ALDatabase *db = [ALDatabase databaseWithPath:[TestUser databasePath]];
    XCTAssertNotNil(db);
}

- (void)testSQLSelect {
    ALDatabase *db = [ALDatabase databaseWithPath:[TestUser databasePath]];
    XCTAssertNotNil(db);
 
    NSString *sql = [db.SELECT(nil).FROM([TestUser tableName]).WHERE(EQ(@"age", @18)).GROUP_BY(@[@"age"]).ORDER_BY(@[@"age"]) sql];
    XCTAssertEqualObjects(sql, @"SELECT * FROM user WHERE (age = ?) GROUP BY age ORDER BY age");
}

- (void)testSQLUpdate {
    ALDatabase *db = [ALDatabase databaseWithPath:[TestUser databasePath]];
    XCTAssertNotNil(db);

    NSString *sql = [db.UPDATE([TestUser tableName])
                         .VALUES(
                             @{ keypathForClass(TestUser, age):  @20,
                                keypathForClass(TestUser, addr): @"Beijing" })
                         .WHERE(EQ(keypathForClass(TestUser, name), @"alex")) sql];
    XCTAssertEqualObjects(sql, @"UPDATE user SET age=?, addr=? WHERE (name = ?)");

    sql = db.UPDATE([TestUser tableName])
              .POLICY(kALDBConflictPolicyFail)
              .SET(keypathForClass(TestUser, addr), @"Beijing")
              .SET(keypathForClass(TestUser, age), @20)
              .WHERE(EQ(keypathForClass(TestUser, name), @"alex"))
              .sql;
    XCTAssertEqualObjects(sql, @"UPDATE OR FAIL user SET age=?, addr=? WHERE (name = ?)");
}

- (void)testSQLInsert {
    ALDatabase *db = [ALDatabase databaseWithPath:[TestUser databasePath]];
    XCTAssertNotNil(db);

    NSString *sql = db.INSERT([TestUser tableName]).POLICY(kALDBConflictPolicyReplace)
                        .VALUES(@{
                            keypathForClass(TestUser, name): @"alex",
                            keypathForClass(TestUser, age):  @"22",
                            keypathForClass(TestUser, addr): @"Haidian"
                        })
                        .sql;
    ALLogInfo("%@", sql);
    XCTAssertEqualObjects(sql, @"INSERT OR REPLACE INTO user(name, age, addr) VALUES(?, ?, ?)");

    sql = db.INSERT([TestUser tableName])
              .POLICY(kALDBConflictPolicyReplace)
              .SELECT(db.SELECT(@[
                            keypathForClass(TestUser, name),
                            keypathForClass(TestUser, age),
                            keypathForClass(TestUser, addr)
                        ])
                          .FROM([TestUser tableName])
                          .WHERE(IS_NULL(keypathForClass(TestUser, addr)))
                          .LIMIT(@[ @2 ]))
              .sql;
    ALLogInfo("%@", sql);
    XCTAssertEqualObjects(sql, @"INSERT OR REPLACE INTO user(name, age, addr) SELECT name, age, addr FROM user WHERE (addr IS NULL) LIMIT 2");
}


@end
