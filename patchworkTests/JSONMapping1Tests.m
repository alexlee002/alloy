//
//  JSONMapping1Tests.m
//  patchwork
//
//  Created by Alex Lee on 3/28/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ALModel.h"
#import "ALModel+JSON.h"
#import "ALOCRuntime.h"
#import "UtilitiesHeader.h"
#import <objc/runtime.h>

@interface TestCaseUser : ALModel
@property(copy)     NSString    *name;
@property(assign)   NSUInteger   age;
@property(copy)     NSString    *email;
@property(strong)   NSURL       *homepage;
//@property(strong)   NSDate      *brithday;
@end

@implementation TestCaseUser

//- (void)modelCustomTransformBrithdayFromNSNumber:(NSNumber *)timeinterval {
//    self.brithday = [NSDate dateWithTimeIntervalSince1970:timeinterval.doubleValue];
//}

//+ (nullable NSDictionary *)modelCustomPropertyMapper {
//    return @{keypathForClass(TestCaseUser, brithday): @"brithday_timestamp"};
//}

@end


@interface TestCaseUser (Category)
@property(strong)   NSDate      *brithday;
@end
@implementation TestCaseUser (Category)

- (void)setBrithday:(NSDate *)brithday {
    objc_setAssociatedObject(self, @selector(brithday), brithday, OBJC_ASSOCIATION_RETAIN);
}
- (NSDate *)brithday {
    return objc_getAssociatedObject(self, @selector(brithday));
}

@end


@interface JSONMapping1Tests : XCTestCase

@end

@implementation JSONMapping1Tests

- (void)setUp {
    [super setUp];
    YYClassPropertyInfo *p = [TestCaseUser allModelProperties][keypathForClass(TestCaseUser, brithday)];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testJSONTransform {
    NSString *json = @"{\"name\": \"Alex Lee\", "
                     @"\"age\": 35, "
                     @"\"email\": \"alex***@hotmail.com\", "
                     @"\"brithday_timestamp\": 0,"
                     @"\"homepage\":\"https://github.com/alexlee002\"}";
    TestCaseUser *user = [TestCaseUser modelWithJSON:json];
    XCTAssertEqualObjects(user.name, @"Alex Lee");
    XCTAssertEqualObjects(user.email, @"alex***@hotmail.com");
    XCTAssertEqualObjects(user.homepage, [NSURL URLWithString:@"https://github.com/alexlee002"]);
    //XCTAssertEqualObjects(user.brithday, [NSDate dateWithTimeIntervalSince1970:0]);
    XCTAssertEqual(user.age, 35);
}

- (void)testModelTransform {
    TestCaseUser *user = [[TestCaseUser alloc] init];
    user.name          = @"Alex Lee";
    user.age           = 20;

    NSDictionary *json = [user modelToJSONObjectWithCustomTransformers:@{
        keypath(user.age) : ^id(NSString *propertyName, id value) {
        if ([value integerValue] < 12) {
            return @"Child";
        } else if ([value integerValue] < 28) {
            return @"Youth";
        } else if ([value integerValue] < 40) {
            return @"Middle age";
        }
        return @"Elder";
        }
        }];
    
    XCTAssertEqualObjects(castToTypeOrNil(json, NSDictionary)[@"age"], @"Youth");
    
}

@end
