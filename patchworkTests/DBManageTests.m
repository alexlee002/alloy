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
                        .ORDER_BYS(@[ [NSString stringWithFormat:@"%@ & 1 DESC", AS_COL(TestUser, name)] ]) sql];
    XCTAssertEqualObjects(sql, @"SELECT * FROM user ORDER BY user_name & 1 DESC");
}

- (void)testSQLSelect {
    ALDatabase *db = [ALDatabase databaseWithPath:[TestUser databaseIdentifier]];
    XCTAssertNotNil(db);
    if (!db) {
        return;
    }
 
    NSString *sql = [db.SELECT(nil).FROM([TestUser tableName]).WHERE(EQ(@"age", @18)).GROUP_BY(@"age").ORDER_BY(@"age") sql];
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
                             @{ AS_COL(TestUser, age) : @20,
                                AS_COL(TestUser, addr) : @"Beijing" })
                         .WHERE(EQ(AS_COL(TestUser, name), @"alex")) sql];
    XCTAssertEqualObjects(sql, @"UPDATE user SET age=?, address=? WHERE (user_name = ?)");

    sql = db.UPDATE([TestUser tableName])
              .POLICY(kALDBConflictPolicyFail)
              .SET(AS_COL(TestUser, addr), @"Beijing")
              .SET(AS_COL(TestUser, age), @20)
              .WHERE(EQ(AS_COL(TestUser, name), @"alex"))
              .sql;
    XCTAssertEqualObjects(sql, @"UPDATE OR FAIL user SET address=?, age=? WHERE (user_name = ?)");
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
                          .LIMIT(2))
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
    XCTAssert([user saveOrReplce:YES]);
    

    XCTAssertEqualObjects(@"user_name", AS_COL_O(user, name));
    XCTAssertEqualObjects(@"user_name", AS_COL(TestUser, name));
    
    const char *keypath = "user.name";
    NSString *str = [NSString stringWithUTF8String:strchr(keypath, '.') + 1];
    NSLog(@"%@", str);
    
    NSString *sql = nil;
    
    TestUser *user1 = [TestUser modelsWithCondition:AS_COL(TestUser, age).EQ(@35)].firstObject;
    XCTAssertEqualObjects(user1.name, user.name);
    XCTAssertEqualObjects(user1.addr, user.addr);
    user1.age = 40;
    XCTAssert([user1 updateOrReplace:YES]);
    [[TestUser modelsWithCondition:nil] bk_each:^(TestUser *obj) {
        NSLog(@"%@", [obj yy_modelDescription]);
    }];
    XCTAssert([TestUser modelsWithCondition:EQ(AS_COL(TestUser, age), @35)].count == 0);
    XCTAssert([TestUser modelsWithCondition:EQ(AS_COL(TestUser, age), @40)].count == 1);
    
    [user1 deleteRecord];
    XCTAssertTrue([TestUser modelsWithCondition:nil].count == 0);
    
    [TestUser fetcher]
    .WHERE(AS_COL(TestUser, age).GT(@10)
           .AND(AS_COL(TestUser, age).LT(@"20"))
           .AND(AS_COL(TestUser, addr).MATCHS_PREFIX(@"Beijing", matchsAny)))
    .ORDER_BY(DESC_ORDER(AS_COL(TestUser, age)))
    .ORDER_BY(AS_COL(TestUser, name))
    .GROUP_BY(AS_COL(TestUser, addr))
    .OFFSET(5)
    .LIMIT(10)
    .FETCH_MODELS();
    
    NSInteger count = 10;
    NSMutableArray *insertingUsers = [NSMutableArray array];
    for (NSInteger i = 0; i < count; ++i) {
        TestUser *user0 = [[TestUser alloc] init];
        user0.age = 30 + i;
        user0.name = [NSString stringWithFormat:@"alex %zd", i];
        user0.addr = [NSString stringWithFormat:@"BJ %zd", i];
        [insertingUsers addObject:user0];
    }
    XCTAssert([TestUser saveRecords:insertingUsers repleace:YES]);
    
    XCTAssertTrue([TestUser modelsWithCondition:nil].count == count);
    
    [[TestUser fetcher].SELECT(@[@"count(*)"]) fetchWithCompletion:^(FMResultSet * _Nullable rs) {
        [rs next];
        XCTAssertTrue([rs intForColumnIndex:0] == count);
    }];
    
    NSArray *models = [TestUser fetcher].FETCH_MODELS();
    NSLog(@"%@", models);
    XCTAssertTrue(models.count == count);
    
    // test Raw Where
    sql = [TestUser fetcher]
                        .SELECT(@[ @"COUNT(*)" ])
                        .RAW_WHERE(@"age > ? OR addr LIKE ? GROUP BY name LIMIT 100", @[ @10, @"Beijing%" ])
                        .sql;
    XCTAssertEqualObjects(sql, @"SELECT COUNT(*) FROM user WHERE age > ? OR addr LIKE ? GROUP BY name LIMIT 100");
    
    
    sql = [TestUser fetcher].WHERE(AS_COL(TestUser, age).BIT_AND(@2).EQ(@0)).sql;
    XCTAssertEqualObjects(sql, @"SELECT rowid, * FROM user WHERE (age & 2 = ?)");

    sql = [TestUser fetcher]
              .SELECT   (@[ AS_COL(TestUser, name) ])
              .WHERE    (AS_COL(TestUser, addr).EQ(@"Beijing"))
              .ORDER_BY (DESC_ORDER(AS_COL(TestUser, name)))
              .ORDER_BY (AS_COL(TestUser, age))
              .OFFSET   (5)
              .LIMIT    (10)
              .sql;
    XCTAssertEqualObjects(sql, @"SELECT user_name FROM user WHERE (address = ?) ORDER BY user_name DESC, age LIMIT 5, 10");
    
    
    ALSQLCondition *rawSet =[ALSQLCondition conditionWithString:[NSString stringWithFormat:@"%@ = REPLACE(%@, ?, ?)", AS_COL(TestUser, addr), AS_COL(TestUser, addr)] args:@"a", @"b", nil];
    ALSQLUpdateCommand *cmd = [TestUser updateExector].RAW_SET(rawSet);
    NSLog(@"%@", cmd);
    
}


- (void)testSubCommand {
    ALDatabase *db = [ALDatabase databaseWithPath:[TestUser databaseIdentifier]];
    NSString *sql = db.SELECT(@[@"COUNT(*)"]).FROM(db.SELECT(nil).FROM([TestUser tableName])).sql;
    XCTAssertEqualObjects(sql, @"SELECT COUNT(*) FROM (SELECT * FROM user)");

    ALSQLCommand *cmd =
        db.SELECT(@[ @"COUNT(*)" ])
            .FROM(
                db.SELECT(nil)
                    .FROM([TestUser tableName])
                    .WHERE(AS_COL(TestUser, name).MATCHS_PREFIX(@"alex", matchsAny).AND(AS_COL(TestUser, age).GT(@20)))
                    .ORDER_BY(AS_COL(TestUser, name))).WHERE(AS_COL(TestUser, age).LT(@30));
    
    XCTAssertEqualObjects(cmd.sql, @"SELECT COUNT(*) FROM (SELECT * FROM user WHERE (user_name LIKE ?) AND (age > ?) ORDER BY user_name) WHERE (age < ?)");
    NSArray *args =  @[@"alex%", @20, @30 ];
    XCTAssertEqualObjects(cmd.sqlArgs, args);
}


@end
