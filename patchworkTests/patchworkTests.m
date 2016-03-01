//
//  patchworkTests.m
//  patchworkTests
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "StringHelper.h"


@interface patchworkTests : XCTestCase

@end

@implementation patchworkTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)testStringHelper {
    XCTAssertEqualObjects(@"xctassert_equal_objects", [@"XCTAssertEqualObjects" stringByConvertingCamelCaseToUnderscore]);
    
    XCTAssertEqualObjects(@"xct_assert_eqs_objects", [@"XctAssertEQsObjects" stringByConvertingCamelCaseToUnderscore]);
}


@end
