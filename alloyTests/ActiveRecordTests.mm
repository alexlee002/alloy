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
#import "ALDatabase+CoreDB.h"

@protocol FileMetaProtocol <NSObject>
@property(nonatomic, assign)    NSInteger   fid;
@property(nonatomic, assign)    NSInteger   size;
@property(nonatomic, copy)      NSString    *fileName;
@property(nonatomic, copy)      NSString    *basePath;
@property(nonatomic, strong)    NSDate      *mtime;
@end

@interface FileMeta : NSObject <FileMetaProtocol, ALActiveRecord>
@end


@implementation FileMeta
@synthesize fid, size, fileName, basePath, mtime;

AL_SYNTHESIZE_ROWID_ALIAS(fid);

+ (NSString *)databaseIdentifier {
    return [NSTemporaryDirectory() stringByAppendingPathComponent:@"alloyTests.db"];
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
    [self reset];
}

- (void)reset {
    [[NSFileManager defaultManager] removeItemAtPath:[FileMeta databaseIdentifier] error:nil];
}

- (void)testActiveRecord {
    {
        FileMeta *meta = [[FileMeta alloc] init];
        //meta.fid = 1;
        meta.fileName = @"test.jpg";
        meta.basePath = @"/home/test";
        meta.size = 1234567;
        meta.mtime = [NSDate date];
        
        XCTAssertTrue([meta al_saveOrReplace:YES]);
        XCTAssertTrue(meta.al_rowid == 1);
        
        FileMeta *meta1 = [[FileMeta alloc] init];
        meta1.fid = 1;
        meta1.fileName = @"test-a.jpg";
        meta1.basePath = @"/home/test";
        meta1.size = 1234567;
        meta1.mtime = [NSDate date];
        meta1.al_autoIncrement = NO;
        XCTAssertTrue([meta1 al_saveOrReplace:YES]);
        XCTAssertTrue(meta1.al_rowid == 1);
        
    }
    
    {
        XCTAssertTrue([FileMeta al_deleteModelsWithCondition:1]);
        
        FileMeta *meta = [[FileMeta alloc] init];
        //meta.fid = 1;
        meta.fileName = @"test.jpg";
        meta.basePath = @"/home/test";
        meta.size = 1234567;
        meta.mtime = [NSDate date];
        
        XCTAssertTrue([meta al_saveOrReplace:YES]);
        XCTAssertTrue(meta.al_rowid == 1);
        
        FileMeta *meta1 = [[FileMeta alloc] init];
        meta1.fid = 1;
        meta1.fileName = @"test-a.jpg";
        meta1.basePath = @"/home/test";
        meta1.size = 1234567;
        meta1.mtime = [NSDate date];
        //meta1.al_autoIncrement = NO;
        XCTAssertTrue([meta1 al_saveOrReplace:YES]);
        XCTAssertTrue(meta1.al_rowid == 2);
    }

    {
        FileMeta *meta = [[FileMeta alloc] init];
        meta.fid = 1;
        meta.fileName = @"test-b.jpg";
        meta.basePath = @"/home/test-1";
        meta.size = 2131434;
        meta.mtime = [NSDate date];
        
        XCTAssertTrue([meta al_updateOrReplace:YES]);
        XCTAssertTrue(meta.al_rowid == 1);
    }
    
    {
        FileMeta *metaSelect = (FileMeta *)[FileMeta al_modelsWithCondition:ALDB_PROP(FileMeta, fid) == 1].firstObject;
        NSLog(@"%@", [metaSelect al_modelDescription]);

        metaSelect.fileName = @"test-1.jpg";
        XCTAssertTrue([metaSelect al_updateProperties:@[ al_keypath(metaSelect.fileName) ] replace:NO]);
        XCTAssertTrue([FileMeta al_modelsWithCondition:ALDB_PROP(FileMeta, fileName) == "test-1.jpg"].count > 0);

        metaSelect.fileName = @"test-2.jpg";
        XCTAssertTrue([FileMeta al_updateModels:@[ metaSelect ] replace:NO]);
        XCTAssertTrue([FileMeta al_modelsWithCondition:ALDB_PROP(FileMeta, fileName) == "test-2.jpg"].count > 0);
        
        metaSelect.fileName = @"test-3.jpg";
        metaSelect.size = 345678;
        XCTAssertTrue([metaSelect al_updateOrReplace:NO]);

        XCTAssertTrue([FileMeta al_updateProperties:@{ al_keypath(metaSelect.fileName) : @"test-3.jpg" }
                                      withCondition:ALDB_PROP(FileMeta, fid) == 1
                                            replace:NO]);
        XCTAssertTrue([FileMeta al_modelsWithCondition:ALDB_PROP(FileMeta, fileName) == "test-3.jpg"].count > 0);

        XCTAssertTrue([metaSelect al_deleteModel]);
        XCTAssertTrue([FileMeta al_deleteModelsWithCondition:1]);
        XCTAssertTrue([FileMeta al_modelsWithCondition:1].count == 0);
    }
}

- (void)testMultiConnections {
    [FileMeta al_modelsWithCondition:ALDB_PROP(FileMeta, fid)==1];
    
    dispatch_queue_t dq = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t group = dispatch_group_create();
    
    NSInteger batchCount = 20 *5000;
    NSInteger taskCount = 1; //20;
    
    NSInteger ID = 0;
    NSMutableArray *taskDatas = [NSMutableArray arrayWithCapacity:taskCount];
    for (NSInteger i = 0; i < taskCount; ++i) {
        NSMutableArray *files = [NSMutableArray arrayWithCapacity:batchCount];
        for (NSInteger j = 0; j < batchCount; ++j) {
            FileMeta *meta = [[FileMeta alloc] init];
            ++ID;
            meta.fid = ID;
            meta.fileName = [NSString stringWithFormat:@"test-%ld.jpg", ID];
            meta.basePath = [NSString stringWithFormat:@"/home/test-%ld", i + 1];
            meta.size = arc4random();
            meta.mtime = [NSDate date];
            
            [files addObject:meta];
        }
        [taskDatas addObject:files];
    }
    
    __block CFTimeInterval t = CFAbsoluteTimeGetCurrent();
    for (int num = 0; num < taskCount; ++num) {
        dispatch_group_async(group, dq, ^{
            [FileMeta al_saveModels:taskDatas[num] replace:YES];
        });
    }

    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    t = CFAbsoluteTimeGetCurrent() - t;
    NSLog(@"Done! %f", t);

    NSInteger count = [FileMeta al_modelsCountWithCondition:1];
    XCTAssertEqual(count, batchCount * taskCount);
}


@end
