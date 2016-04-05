//
//  patchworkTests.m
//  patchworkTests
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSString+Helper.h"
#import "NSObject+JSONTransform.h"
#import "NSArray+ArrayExtensions.h"


@interface patchworkTests : XCTestCase

@end

@implementation patchworkTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)testStringHelper {
    NSArray *arr = @[ @1, @"2", @(3.1)];
    XCTAssertEqualObjects([arr JSONString] , @"[1,\"2\",3.1]" );
    XCTAssertEqualObjects([[NSOrderedSet orderedSetWithArray:arr] JSONString] , @"[1,\"2\",3.1]" );
    
    XCTAssertEqualObjects(@" \"xctassert_equal_objects", [@" \"XCTAssertEqualObjects" stringByConvertingCamelCaseToUnderscore]);
    XCTAssertEqualObjects(@"m3u8download_request", [@"M3U8DownloadRequest" stringByConvertingCamelCaseToUnderscore]);
    XCTAssertEqualObjects(@"xctassert_equal_objects", [@"XCTAssertEqualObjects" stringByConvertingCamelCaseToUnderscore]);
    XCTAssertEqualObjects(@"xct_assert_eqs_objects", [@"XctAssertEQsObjects" stringByConvertingCamelCaseToUnderscore]);
    XCTAssertEqualObjects(@"xct123assert4eqs5objects6", [@"Xct123Assert4EQs5Objects6" stringByConvertingCamelCaseToUnderscore]);
    XCTAssertEqualObjects(@"xctassert_equal_objects_", [@"XCTAssert_Equal_Objects_" stringByConvertingCamelCaseToUnderscore]);
    XCTAssertEqualObjects(@"_xctassert_equal_objects_", [@"_XCTAssert_Equal_Objects_" stringByConvertingCamelCaseToUnderscore]);
    XCTAssertEqualObjects(@"12xctassert_equal_objects", [@"12XCTAssert_Equal_Objects" stringByConvertingCamelCaseToUnderscore]);
    XCTAssertEqualObjects(@"**", [@"**" stringByConvertingCamelCaseToUnderscore]);
    XCTAssertEqualObjects(@" ** xctassert_equal__objects &&%^abc ", [@" ** xctassert_equal__objects &&%^abc " stringByConvertingCamelCaseToUnderscore]);
    XCTAssertEqualObjects(@" ** xcassert_equal_objects &&%^abc", [@" ** XCAssertEqual_Objects &&%^abc" stringByConvertingCamelCaseToUnderscore]);
    XCTAssertEqualObjects(@"xct_assert_equal_objects", [@"xctAssertEqualObjects" stringByConvertingCamelCaseToUnderscore]);
}

- (void)testArray {
    NSArray *arr = @[];
    XCTAssertNil([arr objectAtIndexSafely:-1]);
}

@end
