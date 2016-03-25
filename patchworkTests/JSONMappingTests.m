//
//  JSONMappingTests.m
//  patchwork
//
//  Created by Alex Lee on 3/25/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "UtilitiesHeader.h"
#import "ALModel.h"

@interface FileMetaModel : ALModel

@property (nonatomic)       UInt64       fsId;
@property (nonatomic, copy) NSString    *fileName;
@property (nonatomic, copy) NSString    *parentPath;
@property (nonatomic, copy) NSString    *fullPath;
@property (nonatomic)       BOOL         isdir;
@property (nonatomic)       UInt64       size;
@property (nonatomic)       NSInteger    category;
@property (nonatomic)       BOOL         isDeleted;
@property (nonatomic)       NSUInteger   revision;
@property (nonatomic)       NSDate *ctime;
@property (nonatomic)       NSTimeInterval mtime;
@property (nonatomic, copy) NSString    *md5;

@property (nonatomic, copy) NSString    *operatorName;
@property (nonatomic, copy) NSString    *operatorUk;
@property (nonatomic)       NSInteger    shareMode;
@property (nonatomic, copy) NSString    *ownerUk;

@end

NSString *const kFileMetaModelStatus         = @"status";
NSString *const kFileMetaModelCtime          = @"ctime";
NSString *const kFileMetaModelOperName       = @"oper_name";
NSString *const kFileMetaModelOperUk         = @"oper_uk";
NSString *const kFileMetaModelIsdir          = @"isdir";
NSString *const kFileMetaModelRevision       = @"revision";
NSString *const kFileMetaModelShare          = @"share";
NSString *const kFileMetaModelMtime          = @"mtime";
NSString *const kFileMetaModelCategory       = @"category";
NSString *const kFileMetaModelOwnerUk        = @"owner_uk";
NSString *const kFileMetaModelIsdelete       = @"isdelete";
NSString *const kFileMetaModelPath           = @"path";
NSString *const kFileMetaModelUnlist         = @"unlist";
NSString *const kFileMetaModelSize           = @"size";
NSString *const kFileMetaModelFsId           = @"fs_id";
NSString *const kFileMetaModelServerFilename = @"server_filename";
NSString *const kFileMetaModelServerCtime    = @"server_ctime";
NSString *const kFileMetaModelMd5            = @"md5";
NSString *const kFileMetaModelLocalCtime     = @"local_ctime";
NSString *const kFileMetaModelLocalMtime     = @"local_mtime";
NSString *const kFileMetaModelServerMtime    = @"server_mtime";

@implementation FileMetaModel
+ (NSDictionary<NSString *, NSString *> *)modelCustomPropertyMapper {
    return @{
             keypathForClass(FileMetaModel, fsId):          kFileMetaModelFsId,
             keypathForClass(FileMetaModel, fileName):      kFileMetaModelServerFilename,
             keypathForClass(FileMetaModel, fullPath):      kFileMetaModelPath,
             keypathForClass(FileMetaModel, size):          kFileMetaModelSize,
             keypathForClass(FileMetaModel, ctime):         kFileMetaModelServerCtime,
             keypathForClass(FileMetaModel, mtime):         kFileMetaModelServerMtime,
             keypathForClass(FileMetaModel, isdir):         kFileMetaModelIsdir,
             keypathForClass(FileMetaModel, category):      kFileMetaModelCategory,
             keypathForClass(FileMetaModel, isDeleted):     kFileMetaModelIsdelete,
             keypathForClass(FileMetaModel, ownerUk):       kFileMetaModelOwnerUk,
             keypathForClass(FileMetaModel, shareMode):     kFileMetaModelShare,
             keypathForClass(FileMetaModel, operatorName):  kFileMetaModelOperName,
             keypathForClass(FileMetaModel, operatorUk):    kFileMetaModelOperUk,
             };
}

- (void)setFullPath:(NSString *)fullPath {
    NSString *dir  = [fullPath stringByDeletingLastPathComponent];
    NSString *name = [fullPath lastPathComponent];
    
    self.fileName   = name;
    self.parentPath = dir;
}

- (nullable NSString *)fullPath {
    return [self.parentPath stringByAppendingPathComponent:self.fileName];
}

@end


@interface JSONMappingTests : XCTestCase

@end

@implementation JSONMappingTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    
    NSString *json = @"{\"fs_id\":57170393118567,\"server_filename\":\"\u65b0\u5efa\u6587\u4ef6\u5939\",\"size\":0,\"server_mtime\":1453118516,\"server_ctime\":1453118516,\"local_mtime\":1453118516,\"local_ctime\":1453118516,\"isdir\":1,\"status\":0,\"category\":6,\"share\":0,\"isdelete\":0,\"revision\":0,\"path\":\"\/pic\/\u65b0\u5efa\u6587\u4ef6\u5939(1)\/\u65b0\u5efa\u6587\u4ef6\u5939\",\"md5\":\"\",\"mtime\":1453118516,\"ctime\":1453118516,\"unlist\":0,\"owner_uk\":1160614157,\"oper_name\":\"ss1\u7ba1\u7406\u5458\",\"oper_uk\":1580022285}";
    
    FileMetaModel *model = [FileMetaModel modelWithJSON:json];
    [self measureBlock:^{
        for (int i = 0; i < 10000; ++i) {
            [model modelToJSONData];
        }
    }];
}

@end
