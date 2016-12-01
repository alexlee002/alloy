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

@interface FoundationsTests : XCTestCase

@end

@implementation FoundationsTests

- (void)setUp {
    [super setUp];
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

@end
