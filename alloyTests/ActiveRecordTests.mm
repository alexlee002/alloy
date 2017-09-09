//
//  ActiveRecordTests.m
//  alloy
//
//  Created by Alex Lee on 05/09/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSObject+AL_ActiveRecord.h"
#import "ALActiveRecord.h"
#import "ALUtilitiesHeader.h"
#import "YYClassInfo.h"
#import "NSObject+ALModel.h"

@interface FileMeta : NSObject <ALActiveRecord>
@property(nonatomic, assign)    NSInteger   fid;
@property(nonatomic, assign)    NSInteger   size;
@property(nonatomic, copy)      NSString    *fileName;
@property(nonatomic, copy)      NSString    *basePath;
@property(nonatomic, strong)    NSDate      *mtime;
@end

@implementation FileMeta

- (const std::string)cstring { return ""; }

+ (NSString *)databaseIdentifier {
    return @"/Users/alexlee/Desktop/aldb-test/aldb.db";
}

+ (BOOL)autoBindDatabase { return YES; }

+ (nullable NSArray<NSString *> *)columnPropertyWhitelist {
    return @[
        al_keypathForClass(FileMeta, fid),
        al_keypathForClass(FileMeta, basePath),
        al_keypathForClass(FileMeta, fileName),
        al_keypathForClass(FileMeta, size),
        al_keypathForClass(FileMeta, mtime),
    ];
}

+ (nullable NSArray<NSArray<NSString *> *> *)uniqueKeys {
    return @[
        @[ al_keypathForClass(FileMeta, fid) ],
        @[ al_keypathForClass(FileMeta, basePath), al_keypathForClass(FileMeta, fileName) ]
    ];
}

+ (void)customDefineColumn:(ALDBColumnDefine &)cloumn forProperty:(in YYClassPropertyInfo *_Nonnull)property {

}

@end


@interface ActiveRecordTests : XCTestCase

@end

@implementation ActiveRecordTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)testActiveRecord {
    {
        FileMeta *meta = [[FileMeta alloc] init];
        meta.fid = 1;
        meta.fileName = @"test.jpg";
        meta.basePath = @"/home/test";
        meta.size = 1234567;
        meta.mtime = [NSDate date];
        
        XCTAssertTrue([meta al_saveOrReplace:YES]);
    }
    

    {
        FileMeta *meta = [FileMeta al_modelsWithCondition:AS_COL(FileMeta, fid)==1].firstObject;
        NSLog(@"%@", [meta al_modelDescription]);
        XCTAssertTrue(meta == nil || (meta.fid == 1 && meta.al_rowid != 0));
        
        meta.fileName = @"test-1.jpg";
        XCTAssertTrue([meta al_updateProperties:@[al_keypath(meta.fileName)] replace:NO]);
        
        XCTAssertTrue([meta al_deleteModel]);
        XCTAssertTrue([FileMeta al_modelsWithCondition:1].count == 0);
    }

}


@end
