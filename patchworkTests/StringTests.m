//
//  StringTests.m
//  patchwork
//
//  Created by Alex Lee on 28/10/2016.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ALStringInflector.h"

@interface StringTests : XCTestCase

@end

@implementation StringTests

- (void)testPluraize {
    XCTAssertEqualObjects([@"person" pluralize], @"people");
    XCTAssertEqualObjects([@"tomato" pluralize], @"tomatoes");
    XCTAssertEqualObjects([@"matrix" pluralize], @"matrices");
    XCTAssertEqualObjects([@"octopus" pluralize], @"octopi");
    XCTAssertEqualObjects([@"fish" pluralize], @"fish");
    
    XCTAssertEqualObjects([@"fileDownload" pluralize], @"fileDownloads");
    XCTAssertEqualObjects([@"fileDownload_" pluralize], @"fileDownload_s");
}

@end
