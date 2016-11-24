//
//  patchworkTests.m
//  patchworkTests
//
//  Created by 吴晓龙 on 16/10/11.
//  Copyright © 2016年 Alex Lee. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ALLogger.h"

@interface patchworkTests : XCTestCase

@end

@implementation patchworkTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)testLog {
    NSString *message = @"com.apple.locationd.Utility, category: Utility, enable_level: 0, persist_level: 0, default_ttl: 0, info_ttl: 0, debug_ttl: 0, generate_symptoms: 0, enable_oversize: 0, privacy_setting: 1, enable_private_data: 0";
    ALLogVerbose(@"%@", message);
    ALLogInfo(@"%@", message);
    ALLogWarn(@"%@", message);
    ALLogError(@"%@", message);
}

@end
