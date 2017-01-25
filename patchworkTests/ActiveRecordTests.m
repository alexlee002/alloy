//
//  ActiveRecordTests.m
//  patchwork
//
//  Created by Alex Lee on 31/10/2016.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ALModel.h"
#import "ALSQLClause.h"
#import "ALSQLClause+SQLOperation.h"
#import "ALLogger.h"

static NSString * kTmpDBPath1 = @"patchwork/testcase.activerecord1.db";
static NSString * kTmpDBPath2 = @"patchwork/testcase.activerecord2.db";
static NSString * kTmpDBPath3 = @"patchwork/testcase.activerecord3.db";

@interface Student : ALModel
@property(nonatomic, assign)    NSInteger    sid;
@property(nonatomic, copy)      NSString    *name;
@property(nonatomic, strong)    NSNumber    *age;
@property(nonatomic, assign)    NSInteger    gender;
@property(nonatomic, copy)      NSString    *province;
@property(nonatomic, strong)    NSDate      *birthday;
@property(nonatomic, strong)    UIImage     *icon;

@end

@implementation Student

+ (NSString *)databaseIdentifier {
    return kTmpDBPath1;
}

// It's better use 'rowid' instead of defining a property named 'sid' as primary key.
// If you DO want to do that, you need to make it as alias of 'rowid' and use it as primary key.
SYNTHESIZE_ROWID_ALIAS(sid);

+ (NSArray<NSArray<NSString *> *> *)uniqueKeys {
    return @[ @[ keypathForClass(Student, name) ] ]; // just for test
}

@end

@interface Course : ALModel
@property(nonatomic, assign)    NSInteger    cid;
@property(nonatomic, copy)      NSString    *name;

@end

@implementation Course

+ (NSString *)databaseIdentifier {
    return kTmpDBPath2;
}
SYNTHESIZE_ROWID_ALIAS(cid);

@end



@interface StudentCourse : ALModel
@property(nonatomic, assign)    NSInteger   sid;
@property(nonatomic, assign)    NSInteger   cid;
@end

@implementation StudentCourse

+ (NSString *)databaseIdentifier {
    return kTmpDBPath3;
}

@end




@interface ActiveRecordTests : XCTestCase

@end

@implementation ActiveRecordTests

- (void)setUp {
    [super setUp];
    kTmpDBPath1 = [NSTemporaryDirectory() stringByAppendingPathComponent:kTmpDBPath1];
    kTmpDBPath2 = [NSTemporaryDirectory() stringByAppendingPathComponent:kTmpDBPath2];
    kTmpDBPath3 = [NSTemporaryDirectory() stringByAppendingPathComponent:kTmpDBPath3];
}

- (void)tearDown {
    [self cleanUp];
}

- (void)cleanUp {
    [[NSFileManager defaultManager] removeItemAtPath:kTmpDBPath1 error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:kTmpDBPath2 error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:kTmpDBPath3 error:nil];
}

- (void)testActiveRecord {    
    Student *student = [[Student alloc] init];
    student.name = @"Alex Lee";
    student.age  = @(19);
    student.gender   = 1;
    student.province = @"GD/HS";
    student.birthday = [NSDate date];
    student.icon = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://baidu.com/favicon.ico"]]];
    XCTAssertGreaterThan([student saveOrReplce:YES], 0);
    XCTAssertEqual([Student fetcher].FETCH_COUNT(nil), 1);
    
    student.age = @(student.age.integerValue + 1);
    [student updateOrReplace:YES];
    XCTAssertEqual([[Student modelWithId:student.rowid] age].integerValue, 20);
    
    [student deleteRecord];
    XCTAssertEqual([Student fetcher].FETCH_COUNT(nil), 0);

    student = [Student modelsWithCondition:AS_COL(Student, name)
                                               .PREFIX_LIKE(@"Alex")
                                               .AND(AS_COL(Student, age).NLT(@10))
                                               .AND(AS_COL(Student, age).LT(@20))
                                               .AND(AS_COL(Student, gender).EQ(@1))]
                  .firstObject;
    
    student = [Student fetcher]
                  .WHERE(AS_COL(Student, name).PREFIX_LIKE(@"Alex"))
                  .ORDER_BY(AS_COL(Student, age).DESC())
                  .LIMIT(@1)
                  .OFFSET(@5)
                  .FETCH_MODELS()
                  .firstObject;
    
    [student updateProperties:@[keypath(student.age), keypath(student.province)] repleace:NO];

    [Student updateProperties:@{
        keypathForClass(Student, age) : @20,
        keypathForClass(Student, gender) : @1
    }
                withCondition:AS_COL(Student, birthday).EQ([NSDate dateWithTimeIntervalSinceNow:-20 * 365 * 86400])
                     repleace:NO];
}

- (void)testActiveRecord1 {
    // clean up
    [StudentCourse deleteRecordsWithCondition:nil];
    [Student deleteRecordsWithCondition:nil];
    XCTAssertEqual([Student fetcher].FETCH_COUNT(nil), 0);
    XCTAssertEqual([StudentCourse fetcher].FETCH_COUNT(nil), 0);
    
    Student *student = [[Student alloc] init];
    student.name = @"Alex Lee";
    student.age  = @(19);
    student.gender   = 1;
    student.province = @"GD/HS";
    XCTAssertGreaterThan([student saveOrReplce:YES], 0);
    
    Course *course = [[Course alloc] init];
    course.name = @"The C Language Programming";
    XCTAssertGreaterThan([course saveOrReplce:YES], 0);
    
    StudentCourse *sc = [[StudentCourse alloc] init];
    sc.sid = student.sid;
    sc.cid = course.cid;
    XCTAssertGreaterThan([sc saveOrReplce:YES], 0);
    
    
//    // the following code would cause a dead lock......WTF!!!
//    [Student inTransaction:^(ALDatabase * _Nonnull bindingDB, BOOL * _Nonnull rollback) {
//        [StudentCourse inTransaction:^(ALDatabase * _Nonnull bindingDB, BOOL * _Nonnull rollback2) {
//            // delete student would cause a dead lock....  we need to operate at thread1 from thread2, but thread1 waits thread2 to release....
//            *rollback2 = ![student deleteRecord] || ![StudentCourse deleteRecordsWithCondition:AS_COL(StudentCourse, sid).EQ(@(student.sid))];
//            *rollback = *rollback2;
//        }];
//        XCTAssertEqual([Student fetcher].FETCH_COUNT(nil), 0);
//        XCTAssertEqual([StudentCourse fetcher].FETCH_COUNT(nil), 0);
//    }];
    
    // this can work, but there is too much restrictions
    [Student inTransaction:^(ALDatabase * _Nonnull bindingDB, BOOL * _Nonnull rollback) {
        if (![student deleteRecord]) {
            *rollback = YES;
            return;
        }
        [StudentCourse inTransaction:^(ALDatabase * _Nonnull bindingDB, BOOL * _Nonnull rollback1) {
            if (![StudentCourse deleteRecordsWithCondition:AS_COL(StudentCourse, sid).EQ(@(student.sid))]) {
                *rollback = YES;
                *rollback1 = YES;
            }
        }];
    }];
    XCTAssertEqual([Student fetcher].FETCH_COUNT(nil), 0);
    XCTAssertEqual([StudentCourse fetcher].FETCH_COUNT(nil), 0);
}

#ifdef AL_ENABLE_ROWID_TRIGGER
- (void)testActiveRecord2 {
    Student *s1 = [[Student alloc] init];
    s1.name = @"Alex Lee";
    s1.age  = @(35);
    s1.gender   = 1;
    s1.province = @"BJ/BJ";
    [s1 saveOrReplce:YES];
    NSInteger oldS1Id = s1.rowid;
    
    Student *s2 = [[Student alloc] init];
    s2.name = @"Alex Lee";
    s2.province = @"GD/GZ";
    [s2 saveOrReplce:YES];
    
    
    XCTAssertEqual(s1.rowid, s2.rowid);
    XCTAssertNotEqual(s1.rowid, oldS1Id);
}
#endif

@end
