//
//  FoundationsTests.m
//  patchwork
//
//  Created by Alex Lee on 24/11/2016.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "URLHelper.h"
#import "ALLogger.h"
#import "ALAssociatedWeakObject.h"
#import "ALOCRuntime.h"
#import "UtilitiesHeader.h"
#import "Singleton_Template.h"

void setAge(int age) AL_C_PARAM_ASSERT(age >= 0 && age < 150, "Oh! you're the God!") {
    printf("I'm %d years old", age);
}

#pragma mark - swizzle test
@interface SwizzleCls : NSObject
@end
@implementation SwizzleCls

- (NSString *)instance_sel {
    NSLog(@"I'm original INSTANCE method");
    return @"instance_sel";
}

+ (NSString *)class_sel {
    NSLog(@"I'm original CLASS method");
    return @"class_sel";
}

- (NSString *)instance_sel_swizzled {
    NSLog(@"SWIZZLED  INSTANCE method");
    return @"instance_swizzled";
}

+ (NSString *)class_sel_swizzled {
    NSLog(@"SWIZZLED  CLASS method");
    return @"class_swizzled";
}

@end

///////////////////////////////////////////////////////
#pragma mark - singleton test
@interface SingletonTestBase : NSObject
AS_SINGLETON
@end

@implementation SingletonTestBase
SYNTHESIZE_SINGLETON

- (NSString *)whoAmI {
    return @"SingletonTestBase";
}
@end

@interface SingletonSubClass : SingletonTestBase

@end

@implementation SingletonSubClass
- (NSString *)whoAmI {
    return @"SingletonSubClass";
}
@end

///////////////////////////////////////////////////////
@interface FoundationsTests : XCTestCase
@end
@implementation FoundationsTests

- (void)setUp {
    [super setUp];
    
//    setAge(-1);
//    setAge(151);
//    setAge(5);
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)testURLString {
    NSString *url = @"https://www.google.com.hk/webhp?sourceid=chrome-instant&ion=1&espv=2&ie=UTF-8#q=goo";
    url = [url URLStringByAppendingQueryItems:@[[ALNSURLQueryItem queryItemWithName:@"q" value:@"ios"] ] replace:YES];
    XCTAssertEqualObjects(url, @"https://www.google.com.hk/webhp?sourceid=chrome-instant&ion=1&espv=2&ie=UTF-8&q=ios#q=goo");
    
    
    url = @"https://www.google.com.hk/webhp?sourceid=chrome-instant&ion=1&espv=2&ie=UTF-8&q=goo";
    url = [url URLStringByAppendingQueryItems:@[[ALNSURLQueryItem queryItemWithName:@"q" value:@"ios"],
                                                [ALNSURLQueryItem queryItemWithName:@"ie" value:@"GBK"],
                                                [ALNSURLQueryItem queryItemWithName:@"o" value:@"json"]] replace:YES];
    XCTAssertEqualObjects(url, @"https://www.google.com.hk/webhp?sourceid=chrome-instant&ion=1&espv=2&ie=GBK&q=ios&o=json");
    
    
    url = @"https://www.google.com.hk/webhp?sourceid=chrome-instant&ion=1&espv=2&ie=UTF-8&q=goo";
    url = [url URLStringByAppendingQueryItems:@[[ALNSURLQueryItem queryItemWithName:@"q" value:@"ios"],
                                                [ALNSURLQueryItem queryItemWithName:@"ie" value:@"GBK"],
                                                [ALNSURLQueryItem queryItemWithName:@"o" value:@"json"]] replace:NO];
    XCTAssertEqualObjects(url, @"https://www.google.com.hk/webhp?sourceid=chrome-instant&ion=1&espv=2&ie=UTF-8&q=goo&q=ios&ie=GBK&o=json");
    
    ALLogVerbose(@"%@", url);
}

- (void)testRunAtDealloc {
    NSArray *array = @[@"array"];
    __block int flag = 1;
    [array runAtDealloc:^{
        ALLogInfo(@"~~ DEALLOC~~");
        flag = 0;
    }];
}

- (void)testSwizzle {
    SwizzleCls *test = [[SwizzleCls alloc] init];
    
    swizzle_method(test.class, YES, @selector(class_sel), @selector(class_sel_swizzled));
    swizzle_method(test.class, NO, @selector(instance_sel), @selector(instance_sel_swizzled));
    
    XCTAssertEqualObjects([test instance_sel], @"instance_swizzled");
    XCTAssertEqualObjects([SwizzleCls class_sel], @"class_swizzled");
    
    XCTAssertEqualObjects([test instance_sel_swizzled], @"instance_sel");
    XCTAssertEqualObjects([SwizzleCls class_sel_swizzled], @"class_sel");
}

- (void)testSingleton {
    SingletonTestBase *base = [SingletonTestBase sharedInstance];
    XCTAssertEqualObjects(base, [[SingletonTestBase alloc] init]);
    XCTAssertEqualObjects(base, [base copy]);
    
    XCTAssertEqualObjects(base, [base copyWithZone:NULL]);
    
    ALLogInfo(@"%@", [base whoAmI]);
    XCTAssertEqualObjects(@"SingletonTestBase", [base whoAmI]);
    
    base = nil;
    XCTAssertNotNil([SingletonTestBase sharedInstance]);
    
    SingletonSubClass *child = [SingletonSubClass sharedInstance];
    ALLogInfo(@"%@", [child whoAmI]);
    XCTAssertEqualObjects(@"SingletonSubClass", [child whoAmI]);
    
    XCTAssertEqualObjects(child, [[SingletonSubClass alloc] init]);
    XCTAssertEqualObjects(child, [child copy]);
    
    //XCTAssertEqualObjects(child, [SingletonTestBase sharedInstance]); ✘
    XCTAssertNotEqualObjects(child, [SingletonTestBase sharedInstance]);
}

- (void)testSingleton2 {
    // test if singleton implement is thread-safe.
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 20;
    queue.suspended = YES;
    
    NSMutableSet *set = [NSMutableSet set];
    for (NSInteger i = 0; i < 20; ++i) {
        NSOperation *op = [NSBlockOperation blockOperationWithBlock:^{
            id obj = [[SingletonTestBase alloc] init];
            [set addObject:obj];
            ALLogInfo(@"run op #%d finished!", (int)(i+1));
        }];
        [queue addOperation:op];
    }
    queue.suspended = NO;
    
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:3]];
    XCTAssertEqual(set.count, 1);
}

@end
