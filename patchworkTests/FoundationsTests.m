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
#import "ALUtilitiesHeader.h"
#import "Singleton_Template.h"
#import "ALSQLSelectStatement.h"
#import "SafeBlocksChain.h"

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
SYNTHESIZE_SINGLETON(SingletonTestBase)

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

@interface SingletonChildSubClass : SingletonSubClass

@end

@implementation SingletonChildSubClass
- (NSString *)whoAmI {
    return @"SingletonChildSubClass";
}
@end

@interface SingletonSubClass1 : SingletonTestBase

@end

@implementation SingletonSubClass1
- (NSString *)whoAmI {
    return @"SingletonSubClass1";
}
@end

///////////////////////////////////////////////////////
@interface FakeClassTest : NSObject

@end

@implementation FakeClassTest

- (BOOL)isKindOfClass:(Class)aClass {return YES;}

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
    
    al_swizzle_method(test.class, YES, @selector(class_sel), @selector(class_sel_swizzled));
    al_swizzle_method(test.class, NO, @selector(instance_sel), @selector(instance_sel_swizzled));
    
    XCTAssertEqualObjects([test instance_sel], @"instance_swizzled");
    XCTAssertEqualObjects([SwizzleCls class_sel], @"class_swizzled");
    
    XCTAssertEqualObjects([test instance_sel_swizzled], @"instance_sel");
    XCTAssertEqualObjects([SwizzleCls class_sel_swizzled], @"class_sel");
}

- (void)testSingleton {
    SingletonTestBase *base = [SingletonTestBase sharedInstance];
    XCTAssertEqualObjects(base, [[SingletonTestBase alloc] init]);
    XCTAssertEqualObjects(base, [base copy]);
    XCTAssertEqualObjects(base, [SingletonTestBase new]);
    
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
    
    
    XCTAssertNotEqualObjects([SingletonChildSubClass sharedInstance], [SingletonTestBase sharedInstance]);
    XCTAssertNotEqualObjects([SingletonChildSubClass sharedInstance], [SingletonSubClass sharedInstance]);
    XCTAssertNotEqualObjects([SingletonChildSubClass sharedInstance], [SingletonSubClass1 sharedInstance]);
    XCTAssertNotEqualObjects([SingletonSubClass sharedInstance], [SingletonSubClass1 sharedInstance]);
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

- (void)testAutoCreateClass {
//    Class cls = objc_allocateClassPair(NSObject.class, "HelloAlexBad", 0);
//    class_addIvar(cls, "_obj", sizeof(id), log2(sizeof(id)), @encode(id));
//    class_addIvar(cls, "_arr", sizeof(NSArray *), log2(_Alignof(NSArray *)), @encode(NSArray *));
//    uint8_t layout[2] = {0x02, 0x00};
//    class_setIvarLayout(cls, layout);
//    uint8_t layout1[2] = {0x20, 0x00};
//    class_setWeakIvarLayout(cls, layout1);
//    objc_registerClassPair(cls);
//    fixup_class_arc(cls);
//    
//    ALLogInfo(@"%s", class_getIvarLayout(cls));
//    ALLogInfo(@"%s", class_getWeakIvarLayout(cls));
    
//    Method deallocM = class_getInstanceMethod(cls, NSSelectorFromString(@"release"));
//    IMP origDeallocIMP = NULL;
//    
//    origDeallocIMP = method_setImplementation(deallocM, imp_implementationWithBlock(^(id obj) {
//        [obj setValue:nil forKey:@"obj"];
//        [obj setValue:nil forKey:@"arr"];
//        
//        if (origDeallocIMP != NULL) {
//            origDeallocIMP();
//        }
//    }));
    
//    // __weak id weakObj = nil;
//    __weak id weakArr = nil;
//    {
//        id ins = [[cls alloc] init];
//        [ins setValue:[[NSArray alloc] initWithObjects:@"aa", @"bb", nil] forKey:@"arr"];
////        [ins setValue:[[NSObject alloc] init] forKey:@"obj"];
////weakObj = [ins valueForKey:@"obj"];
//        weakArr = [ins valueForKey:@"arr"];
//        //XCTAssertNotNil(weakObj);
//        XCTAssertNotNil(weakArr);
//    }
//    //XCTAssertNil(weakObj); // WARNING: weakRef is not nil! memory leak!
//    XCTAssertNil(weakArr);
//    
//    
//    cls = objc_allocateClassPair(NSObject.class, "HelloAlexGood", 0);
//    class_addIvar(cls, "_obj", sizeof(id), log2(sizeof(id)), @encode(id));
//    class_addIvar(cls, "_arr", sizeof(id), log2(sizeof(id)), @encode(id));
//    objc_registerClassPair(cls);
//    fixup_class_arc(cls);
//    
//    __weak id weakObj1 = nil;
//    __weak id weakArr1 = nil;
//    {
//        id ins = [[cls alloc] init];
//        [ins setValue:[[NSArray alloc] initWithObjects:@"aa", @"bb", nil] forKey:@"arr"];
//        [ins setValue:[[NSObject alloc] init] forKey:@"obj"];
//        weakObj1 = [ins valueForKey:@"obj"];
//        weakArr1 = [ins valueForKey:@"arr"];
//        XCTAssertNotNil(weakObj1);
//        XCTAssertNotNil(weakArr1);
//    }
//    XCTAssertNil(weakObj1); // OK
//    XCTAssertNil(weakArr1);
}

- (void)testSafeBlocksChain {
    al_safeBlocksChainObj(nil, ALSQLSelectStatement)
        .SELECT(@"*")
        .FROM(@"table")
        .WHERE(@"colval = 1")
        .EXECUTE_QUERY(^(FMResultSet *rs) {
            XCTAssertNil(rs);
        });  // ✔
}

@end
