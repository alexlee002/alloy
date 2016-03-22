//
//  DBManageTests.m
//  patchwork
//
//  Created by Alex Lee on 2/19/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ALModel.h"
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
@property(PROP_ATOMIC_DEF, copy)  NSString *name;
@property(PROP_ATOMIC_DEF)        NSInteger age;
@property(PROP_ATOMIC_DEF, copy)  NSString *addr;
@end

@implementation TestUser
@end


@interface TestUser (DBManage)
@end

@implementation TestUser(DBManage)

+ (NSString *)tableName { return @"user"; }
+ (NSString *)databaseIdentifier {
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"test_1.db"];
    return path;
}

+ (nullable NSDictionary<NSString *, NSString *>  *)modelCustomColumnNameMapper {
    return @{keypathForClass(TestUser, name): @"user_name", keypathForClass(TestUser, addr): @"address"};
}

+ (nullable NSArray<NSString *> *)primaryKeys {
    return nil;
}

+ (nullable NSArray<NSArray<NSString *> *> *)uniqueKeys {
    return @[ keypathForClass(TestUser, name) ];
}

+ (nullable NSArray<NSArray<NSString *> *> *)indexKeys {
    return nil;
}

@end


@interface DBManageTests : XCTestCase
@end

@implementation DBManageTests

- (void)setUp {
    [super setUp];
    //[[NSFileManager defaultManager] removeItemAtPath:[TestUser databaseIdentifier] error:nil];
}

- (void)testSetupDB {
    ALDatabase *db = [ALDatabase databaseWithPath:[TestUser databaseIdentifier]];
    XCTAssertNotNil(db);

    NSString *sql = [db.SELECT(nil)
                        .FROM([TestUser tableName])
                        .ORDER_BY(@[ [NSString stringWithFormat:@"%@ & 1 DESC", AS_COL(TestUser, name)] ]) sql];
    XCTAssertEqualObjects(sql, @"SELECT * FROM user ORDER BY user_name & 1 DESC");
}

- (void)testSQLSelect {
    ALDatabase *db = [ALDatabase databaseWithPath:[TestUser databaseIdentifier]];
    XCTAssertNotNil(db);
    if (!db) {
        return;
    }
 
    NSString *sql = [db.SELECT(nil).FROM([TestUser tableName]).WHERE(EQ(@"age", @18)).GROUP_BY(@[@"age"]).ORDER_BY(@[@"age"]) sql];
    XCTAssertEqualObjects(sql, @"SELECT * FROM user WHERE (age = ?) GROUP BY age ORDER BY age");
}

- (void)testSQLUpdate {
    ALDatabase *db = [ALDatabase databaseWithPath:[TestUser databaseIdentifier]];
    XCTAssertNotNil(db);
    if (!db) {
        return;
    }

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
    ALDatabase *db = [ALDatabase databaseWithPath:[TestUser databaseIdentifier]];
    XCTAssertNotNil(db);
    if (!db) {
        return;
    }

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

#pragma mark - active record

- (void)testActiveRecord {
    [[NSFileManager defaultManager] removeItemAtPath:[TestUser databaseIdentifier] error:nil];
    
    TestUser *user = [[TestUser alloc] init];
    user.name = @"Alex Lee";
    user.age = 35;
    user.addr = @"Beijing";
    [user saveOrReplce:YES];
    

    XCTAssertEqualObjects(@"user_name", AS_COL_O(user, name));
    XCTAssertEqualObjects(@"user_name", AS_COL(TestUser, name));
    
    const char *keypath = "user.name";
    NSString *str = [NSString stringWithUTF8String:strchr(keypath, '.') + 1];
    NSLog(@"%@", str);
    
    
    TestUser *user1 = [TestUser modelsWithCondition:EQ(AS_COL(TestUser, age), @35)].firstObject;
    XCTAssertEqualObjects(user1.name, user.name);
    XCTAssertEqualObjects(user1.addr, user.addr);
    
    user1.age = 40;
    [user1 updateOrReplace:YES];
    XCTAssertTrue([TestUser modelsWithCondition:EQ(AS_COL(TestUser, age), @35)].count == 0);
    XCTAssertTrue([TestUser modelsWithCondition:EQ(AS_COL(TestUser, age), @40)].count == 1);
    
    [user1 deleteRecord];
    XCTAssertTrue([TestUser modelsWithCondition:nil].count == 0);
    
    NSInteger count = 10;
    for (NSInteger i = 0; i < count; ++i) {
        TestUser *user0 = [[TestUser alloc] init];
        user0.age = 30 + i;
        user0.name = [NSString stringWithFormat:@"alex %zd", i];
        user0.addr = [NSString stringWithFormat:@"BJ %zd", i];
        [user0 saveOrReplce:YES];
    }
    XCTAssertTrue([TestUser modelsWithCondition:nil].count == count);
    
    [[TestUser fetcher].SELECT(@[@"count(*)"]) fetchWithCompletion:^(FMResultSet * _Nullable rs) {
        [rs next];
        XCTAssertTrue([rs intForColumnIndex:0] == count);
    }];
    
    NSArray *models = [TestUser fetcher].FETCH_MODELS();
    NSLog(@"%@", models);
    XCTAssertTrue(models.count == count);
    
    // test Raw Where
    NSString *sql = [TestUser fetcher]
                        .SELECT(@[ @"COUNT(*)" ])
                        .RAW_WHERE(@"age > ? OR addr LIKE ? GROUP BY name LIMIT 100", @[ @10, @"Beijing%" ])
                        .sql;
    XCTAssertEqualObjects(sql, @"SELECT COUNT(*) FROM user WHERE age > ? OR addr LIKE ? GROUP BY name LIMIT 100");
    
    
    sql = [TestUser fetcher].WHERE(EQ(BIT_AND(AS_COL(TestUser, age), @2), @0)).sql;
    XCTAssertEqualObjects(sql, @"SELECT rowid, * FROM user WHERE (age & 2 = ?)");
}


@end
