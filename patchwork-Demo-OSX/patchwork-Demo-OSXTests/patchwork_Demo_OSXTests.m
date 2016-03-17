//
//  patchwork_Demo_OSXTests.m
//  patchwork-Demo-OSXTests
//
//  Created by Alex Lee on 3/17/16.
//  Copyright © 2016 me.alexlee002. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ALDevice.h"

@interface patchwork_Demo_OSXTests : XCTestCase

@end

@implementation patchwork_Demo_OSXTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    XCTAssertEqualObjects([ALDevice currentDevice].systemName, @"OS X");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
