//
//  FoundationTests.m
//  alloyTests
//
//  Created by Alex Lee on 23/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSArray+ALExtensions.h"
#import "NSString+ALHelper.h"
#import "ALSingletonTemplate.h"
#import "TimedQueue.hpp"
#import "ALURLHelper.h"
#import "ALMacros.h"
#import "YYClassInfo.h"


@interface TestSingleton: NSObject
AL_AS_SINGLETON;
@end
@implementation TestSingleton
AL_SYNTHESIZE_SINGLETON(TestSingleton);
@end

@interface TestWeakSingleton: NSObject
AL_AS_WEAK_SINGLETON;
@end
@implementation TestWeakSingleton
AL_SYNTHESIZE_WEAK_SINGLETON(TestWeakSingleton);

- (void)dealloc {
    ALLogInfo(@"~~~ %@ ~~~", self);
}
@end

@interface TestSingletonChild : TestSingleton
AL_AS_SINGLETON;
@end
@implementation TestSingletonChild
//!!! if the following line is omitted, the instance of TestSingletonChild is the same instance of TestSingleton.
AL_SYNTHESIZE_SINGLETON(TestSingletonChild);
@end

#define auto_var(name)  __tmp_ ## name ## (__LINE__)

@interface FoundationTests : XCTestCase

@end

@implementation FoundationTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.

}

- (void)testURLComponents {
    {
        NSString *charsets     = @"~`!@#$%^&*()-=_+[]\\{}|;':\",./<>?";
        NSURLComponents *comps = [[NSURLComponents alloc] init];
        comps.queryItems       = @[ [NSURLQueryItem queryItemWithName:@"key" value:charsets] ];
        NSLog(@"components.percentEncodeQuery: %@", comps.percentEncodedQuery);
        
        NSURLComponents *compsAL = [[NSURLComponents alloc] init];
        ALURLQueryItem *alItem = [ALURLQueryItem queryItemWithName:@"key" value:charsets];
        compsAL.al_queryItems = @[ alItem ];
        XCTAssertEqualObjects(comps.percentEncodedQuery, compsAL.percentEncodedQuery);
        
        if (@available(iOS 11.0, *)) {
            NSURLQueryItem *item = comps.percentEncodedQueryItems.firstObject;
            XCTAssertEqualObjects(item.value, alItem.percentEncodedValue);
        }
    }

    {
        NSString *encodedQuery = @"urlencode=UrlEncode%e7%bc%96%e7%a0%81%2f%e8%a7%a3%e7%a0%81&base64=VXJsRW5jb2Rl57yW56CBL+ino+eggQ==&a%20b%2Fc=dddd%20%2C%23eee";
        NSURLComponents *comps = [[NSURLComponents alloc] init];
        comps.percentEncodedQuery = encodedQuery;
        
        NSLog(@"query: %@", comps.query);
        NSLog(@"NSQueryItems: %@", comps.queryItems);
        NSLog(@"ALQueryItems: %@", comps.al_queryItems);
        
        NSString *query = [ALURLHelper queryStringWithItems:comps.al_queryItems];
        comps.queryItems = comps.queryItems;
        XCTAssertEqualObjects(query, comps.percentEncodedQuery);
    }
}

- (void)testRuntimeInvokeMacros {
    NSNumber *obj = @123.456;
    YYClassMethodInfo *m = [YYClassInfo classInfoWithClass:NSNumber.class].methodInfos[@"floatValue"];
    if (m) {
        CGFloat f = ((CGFloat(*)(id, SEL))m.imp)(obj, m.sel);
    }
    
//    Class cls = [obj class];                                     \
//    SEL sel = @selector(floatValue);
//    if (NO) {                                               \
//        cls = objc_getMetaClass(class_getName(cls));                     \
//    }                                                                    \
//    if (cls != Nil && class_respondsToSelector(cls, sel)) {              \
//        IMP imp = class_getMethodImplementation(cls, sel);               \
//        if (imp) {                                                       \
//            CGFloat f = (CGFloat)(imp(obj, sel));           \
//        }                                                                \
//    }
//
//
//    CGFloat f = al_safeInvokeMethod(CGFloat, number, @selector(floatValue));
//    XCTAssertEqual(123.456, f);
}

- (void)testTimeQueue {
    static aldb::TimedQueue<std::string> sTimeQueue(500);

    static std::thread sTimedThread([]() {
        pthread_setname_np("timed-thread");
        while (true) {
            sTimeQueue.wait_until_expired([](const std::string &name) { ALLogInfo(@"%s timeout!", name.c_str()); });
        }
    });
    static std::once_flag s_flag;
    std::call_once(s_flag, []() { sTimedThread.detach(); });

    for (int i = 0; i < 10; ++i) {
        std::string name = "test-case-" + std::to_string(i);
        sTimeQueue.requeue(name);
        ALLogInfo(@"%s enqueue!", name.c_str());
        [NSThread sleepForTimeInterval:0.3];
    }
    
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:10.f]];
    
    //[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:5.f]];
}

- (void)testWeakSingleton {
    __weak TestWeakSingleton *weakRef = nil;
    // instance1
    @autoreleasepool{
        TestWeakSingleton *weakSingleton1 = [TestWeakSingleton sharedInstance];
        TestWeakSingleton *weakSingleton2 = [[TestWeakSingleton alloc] init];
        XCTAssertEqualObjects(weakSingleton1, weakSingleton2);
        weakRef = weakSingleton1;
    }
    
    // instance2
    @autoreleasepool{
        //instance1 is already deleted,  the next line will create a new instance
        TestWeakSingleton *weakSingleton1 = [TestWeakSingleton sharedInstance];
        TestWeakSingleton *weakSingleton2 = [[TestWeakSingleton alloc] init];
        XCTAssertEqualObjects(weakSingleton1, weakSingleton2);
        XCTAssertNotEqualObjects(weakRef, weakSingleton1); // instance1 != instance2
    }
}

- (void)testSingleton {
    __weak TestSingleton *weakRef = nil;
    @autoreleasepool{
        TestSingleton *weakSingleton1 = [TestSingleton sharedInstance];
        TestSingleton *weakSingleton2 = [[TestSingleton alloc] init];
        XCTAssertEqualObjects(weakSingleton1, weakSingleton2);
        weakRef = weakSingleton1;
    }
    
    @autoreleasepool{
        TestSingleton *weakSingleton1 = [TestSingleton sharedInstance];
        TestSingleton *weakSingleton2 = [[TestSingleton alloc] init];
        XCTAssertEqualObjects(weakSingleton1, weakSingleton2);
        XCTAssertEqualObjects(weakRef, weakSingleton1);
    }
}

- (void)testSingletonInheritance {
    TestSingleton *base = [TestSingleton sharedInstance];
    TestSingletonChild *child = [TestSingletonChild sharedInstance];
    XCTAssertNotEqualObjects(base, child);
    
    TestSingletonChild *child2 = [TestSingletonChild sharedInstance];
    XCTAssertEqualObjects(child2, child);
}

- (void)testSubstring {
    NSString *string = @"01234567";
    {
        XCTAssertEqualObjects(@"567", [string al_substringFromIndex:5]);
        XCTAssertEqualObjects(@"567", [string al_substringFromIndex:-3]);
        // out of bounds
        XCTAssertNil([string al_substringFromIndex:10]);
        XCTAssertEqualObjects(string, [string al_substringFromIndex:-10]);
    }

    {
        XCTAssertEqualObjects(@"012", [string al_substringToIndex:3]);
        XCTAssertEqualObjects(@"012", [string al_substringToIndex:-5]);
        XCTAssertEqualObjects(string, [string al_substringToIndex:string.length]);
        // out of bounds
        XCTAssertNil([string al_substringToIndex:-10]);
        XCTAssertEqualObjects(string, [string al_substringToIndex:10]);
    }
    
    {
        XCTAssertEqualObjects(@"345", [string al_substringFromIndex:3 length:3]);
        XCTAssertEqualObjects(@"345", [string al_substringFromIndex:-5 length:3]);
        XCTAssertEqualObjects(@"345", [string al_substringFromIndex:-5 length:-2]);
        XCTAssertEqualObjects(@"345", [string al_substringFromIndex:3 length:-2]);
        // out of bounds
        XCTAssertNil([string al_substringFromIndex:10 length:3]);
        XCTAssertNil([string al_substringFromIndex:10 length:-10]);
        XCTAssertNil([string al_substringFromIndex:-10 length:-10]);
        XCTAssertEqualObjects(@"34567", [string al_substringFromIndex:-5 length:10]);
        XCTAssertEqualObjects(string, [string al_substringFromIndex:-10 length:10]);
    }
}

- (void)testSubarray {
    NSArray<NSString *> *array = @[@"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7"];
    NSArray<NSString *> *result = nil;

    {
        result = @[ @"5", @"6", @"7" ];
        XCTAssertEqualObjects(result, [array al_subarrayFromIndex:5]);
        XCTAssertEqualObjects(result, [array al_subarrayFromIndex:-3]);  // from right to left
        // out of bounds
        XCTAssertNil([array al_subarrayFromIndex:10]);
        XCTAssertEqualObjects(array, [array al_subarrayFromIndex:-10]);
    }

    {
        result = @[ @"0", @"1", @"2" ];
        XCTAssertEqualObjects(result, [array al_subarrayToIndex:3]);
        XCTAssertEqualObjects(result, [array al_subarrayToIndex:-5]);
        // out of bounds
        XCTAssertNil([array al_subarrayToIndex:-10]);
        XCTAssertEqualObjects(array, [array al_subarrayToIndex:10]);
    }

    {
        //@see: php -r 'print_r(array_slice(array("0", "1", "2", "3", "4", "5", "6", "7"), -10, 10));'
        result = @[ @"3", @"4", @"5" ];
        XCTAssertEqualObjects(result, [array al_subarrayFromIndex:3 length:3]);
        XCTAssertEqualObjects(result, [array al_subarrayFromIndex:-5 length:3]);
        XCTAssertEqualObjects(result, [array al_subarrayFromIndex:-5 length:-2]);
        XCTAssertEqualObjects(result, [array al_subarrayFromIndex:3 length:-2]);
        // out of bounds
        XCTAssertNil([array al_subarrayFromIndex:10 length:3]);
        XCTAssertNil([array al_subarrayFromIndex:10 length:-10]);
        XCTAssertNil([array al_subarrayFromIndex:-10 length:-10]);
        result = @[ @"3", @"4", @"5", @"6", @"7" ];
        XCTAssertEqualObjects(result, [array al_subarrayFromIndex:-5 length:10]);
        XCTAssertEqualObjects(array, [array al_subarrayFromIndex:-10 length:10]);
    }
}

@end
