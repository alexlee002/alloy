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
#import "MD5.h"
#import "DES.h"


@interface NSObject (NilTest)

@property(readonly) void (^BlockTest)(void);
@property(readonly) NSString *propTest;

@end

@implementation NSObject(NilTest)

- (void (^)(void))BlockTest {
    return ^{
        NSLog(@"Block test");
    };
}

- (NSString *)propTest {
    return @"Property test";
}

@end


@interface patchworkTests : XCTestCase

@end

@implementation patchworkTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)testStringHelper {
    
    NSObject *obj = nil;
    NSLog(@"=== %@", obj.propTest);
    //obj.BlockTest();
    
    
    
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


- (void)testFileMD5 {
    NSString *tmpfile = [NSTemporaryDirectory() stringByAppendingPathComponent:@"Charles.dmg"];
    NSLog(@"file: %@", tmpfile);
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:tmpfile]) {
        return;
    }
    
    NSString *md5 = fileMD5Hash(tmpfile);
    XCTAssertEqualObjects(@"7a30a08d8e0d896dacd2631169f8116f", md5);
    
    NSDictionary *fileAttrs = [[NSFileManager defaultManager] attributesOfItemAtPath:tmpfile error:nil];
    NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath:tmpfile];
    uint32_t offset = arc4random() % (fileAttrs.fileSize / 2);
    uint32_t length = (uint32_t)MIN(fileAttrs.fileSize - offset, 2 * 1024 * 1024);
    [fh seekToFileOffset:offset];
    NSData *data = [fh readDataOfLength:length];
    [fh closeFile];
    
    md5 = partialFileMD5Hash(tmpfile, NSMakeRange(offset, length));
    XCTAssertEqualObjects([data MD5], md5);
}


- (void)testDES {
    NSData *key = [@"patchwork" dataUsingEncoding:NSUTF8StringEncoding];
    NSString *string = @"NSString *tmpfile = [NSTemporaryDirectory() stringByAppendingPathComponent:@\"Charles.dmg\"];";
    
    NSData *encData = [[string dataUsingEncoding:NSUTF8StringEncoding] dataByDESEncryptingWithKey:key];
    NSData *decData = [encData dataByDESDecryptingWithKey:key];
    NSString *decString = [[NSString alloc] initWithData:decData encoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(decString, string);
}
@end
