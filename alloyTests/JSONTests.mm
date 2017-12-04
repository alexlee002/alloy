//
//  JSONTests.m
//  alloyTests
//
//  Created by Alex Lee on 22/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSObject+ALJSONMapping.h"
#import "TestFileModel.h"
#import "ALMacros.h"

@interface TestFileModel (JSONMapping)
@end
@implementation TestFileModel (JSONMapping)
+ (nullable NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    return @{
        al_keypathForClass(TestFileModel, fid) : @"fs_id",
        al_keypathForClass(TestFileModel, size) : @"file_size",
        al_keypathForClass(TestFileModel, fileName) : @"file_name",
        al_keypathForClass(TestFileModel, basePath) : @"path",
        al_keypathForClass(TestFileModel, mtime) : @"mtime"
    };
}
@end

@interface JSONTests : XCTestCase

@end

@implementation JSONTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)testJSONMapping {
    {
        NSString *json =
            @"[{\"fs_id\":5357037373629, \"file_size\":79757, \"file_name\":\"94266513.jpg\", "
            @"\"path\":\"/测试-勿删/局部装修效果图/吊顶定下/\", \"mtime\":1501825359},{\"fs_id\":790514793631, "
            @"\"file_size\":7241728, \"file_name\":\"DSC07619.JPG\", "
            @"\"path\":\"/反反复复人/多类型图片文件夹/韩国游/第二次来首尔/\", "
            @"\"mtime\":1504596514},{\"fs_id\":394365023360, \"file_size\":84688, \"file_name\":\"11210112Q5.jpg\", "
            @"\"path\":\"/测试-勿删/玄关定下/\", \"mtime\":1501755174},{\"fs_id\":\"778978553121\", "
            @"\"file_size\":56631, "
            @"\"file_name\":\"8888882017-03-02 103438.png\", \"path\":\"/厨房定下/\", "
            @"\"mtime\":\"1504596320\"},{\"fs_id\":587747945175, \"file_size\":\"142206\", "
            @"\"file_name\":\"2755921496975397392.jpg\", \"path\":\"/测试-勿删/jia zhuang/\", \"mtime\":1501740823}]";

        NSArray *files = [NSArray al_modelArrayWithClass:TestFileModel.class JSON:json];
        XCTAssertTrue(files.count == 5);
    }
}


@end
