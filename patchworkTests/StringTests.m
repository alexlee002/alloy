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
    XCTAssertEqualObjects([@"person" al_pluralize], @"people");
    XCTAssertEqualObjects([@"tomato" al_pluralize], @"tomatoes");
    XCTAssertEqualObjects([@"matrix" al_pluralize], @"matrices");
    XCTAssertEqualObjects([@"octopus" al_pluralize], @"octopi");
    XCTAssertEqualObjects([@"fish" al_pluralize], @"fish");
    
    XCTAssertEqualObjects([@"fileDownload" al_pluralize], @"fileDownloads");
    XCTAssertEqualObjects([@"fileDownload_" al_pluralize], @"fileDownload_s");
}

@end
