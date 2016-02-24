//
//  patchworkTests.m
//  patchworkTests
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <XCTest/XCTest.h>



@interface patchworkTests : XCTestCase

@end

@implementation patchworkTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}
//
//- (void)loopTest:(NSInteger)count {
//    GCDSyncTest *t = [[GCDSyncTest alloc] init];
//    [t syncTest:^{
//        NSLog(@"00000000");
//        [t syncTest:^{
//            NSLog(@"1111111");
//        }];
//        NSLog(@"22222222");
//    }];
//}

//- (void)testGCDSync {

//    __block NSInteger val = 0;
//    GCDSyncTest *t = [[GCDSyncTest alloc] init];
//    [t syncTest:^{
//        val = 1;
//        [t syncTest:^{
//            val = 2;
//        }  callerThread:[NSThread currentThread]];
//    } callerThread:[NSThread currentThread]];
//    XCTAssertEqual(val, 2);
//}


@end
