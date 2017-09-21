//
//  JsonMappingTests.m
//  alloy
//
//  Created by Alex Lee on 21/09/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "YYModel.h"
#import "ALUtilitiesHeader.h"
#import "NSObject+AL_JSONMapping.h"

@interface FileModel : NSObject <YYModel>
@property(nonatomic, assign)    NSInteger   fid;
@property(nonatomic, assign)    NSInteger   size;
@property(nonatomic, copy)      NSString    *fileName;
@property(nonatomic, copy)      NSString    *basePath;
@property(nonatomic, strong)    NSDate      *mtime;
@end

@implementation FileModel
+ (nullable NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    return @{
        al_keypathForClass(FileModel, fid) : @"fs_id",
        al_keypathForClass(FileModel, size) : @"file_size",
        al_keypathForClass(FileModel, fileName) : @"file_name",
        al_keypathForClass(FileModel, basePath) : @"path",
        al_keypathForClass(FileModel, mtime) : @"mtime"
    };
}
@end



@interface JsonMappingTests : XCTestCase

@end

@implementation JsonMappingTests

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
            @"\"path\":\"/测试-勿删/玄关定下/\", \"mtime\":1501755174},{\"fs_id\":\"778978553121\", \"file_size\":56631, "
            @"\"file_name\":\"8888882017-03-02 103438.png\", \"path\":\"/厨房定下/\", "
            @"\"mtime\":\"1504596320\"},{\"fs_id\":587747945175, \"file_size\":\"142206\", "
            @"\"file_name\":\"2755921496975397392.jpg\", \"path\":\"/测试-勿删/jia zhuang/\", \"mtime\":1501740823}]";
        
        NSArray *files = [NSArray al_modelArrayWithClass:FileModel.class JSON:json];
        XCTAssertTrue(files.count == 5);
    }
    
    
}


@end
