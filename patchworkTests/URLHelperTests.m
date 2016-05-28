//
//  URLHelperTests.m
//  patchwork
//
//  Created by Alex Lee on 5/29/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "URLHelper.h"

@interface URLHelperTests : XCTestCase

@end

@implementation URLHelperTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)testURL {
    NSURL *url = [NSURL URLWithString:@"http://www.mydoma.me/%E4%B8%AD%E6%96%87?a=1&b=2&a=123"];
    NSURL *url1 = [url URLBySettingQueryParamsOfDictionary:@{}];
    XCTAssertEqualObjects(url, url1);
    
    url1 = [url URLBySettingQueryParamsOfDictionary:@{@"a": @(9000), @"b":@"123abc", @"c": @"wwwww"}];
    NSLog(@"url1: %@", url1);
    XCTAssertEqualObjects(url1.absoluteString, @"http://www.mydoma.me/%E4%B8%AD%E6%96%87?a=9000&b=123abc&c=wwwww");
}

- (void)testURLString {
    NSString *url = @"http://www.mydoma.me/%E4%B8%AD%E6%96%87?a=1&b=2&a=123";
    NSString *url1 = [url URLStringBySettingQueryParamsOfDictionary:@{}];
    XCTAssertEqualObjects(url, url1);
    
    url1 = [url URLStringBySettingQueryParamsOfDictionary:@{@"a": @(9000), @"b":@"123abc", @"c": @"wwwww"}];
    NSLog(@"url1: %@", url1);
    XCTAssertEqualObjects(url1, @"http://www.mydoma.me/%E4%B8%AD%E6%96%87?a=9000&b=123abc&c=wwwww");
}

@end
