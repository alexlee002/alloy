//
//  TestFileModel.m
//  alloyTests
//
//  Created by Alex Lee on 13/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "TestFileModel.h"
#import "ALDBTableBinding.h"
#import "NSObject+ALModel.h"
#import "ALMacros.h"

@implementation TestFileModel
@synthesize fid, size, fileName, basePath, mtime, ctime;

//AL_SYNTHESIZE_ROWID_ALIAS(fid);

+ (NSString *)databaseIdentifier {
    return [NSTemporaryDirectory() stringByAppendingPathComponent:@"alloyTests.db"];
}

+ (BOOL)autoBindDatabase { return YES; }

+ (nullable NSArray<NSString *> *)columnPropertyWhitelist {
    return @[
             al_keypathForClass(TestFileModel, fid),
             al_keypathForClass(TestFileModel, basePath),
             al_keypathForClass(TestFileModel, fileName),
             al_keypathForClass(TestFileModel, size),
             al_keypathForClass(TestFileModel, mtime),
             al_keypathForClass(TestFileModel, ctime),
             ];
}

+ (nullable NSArray<NSArray<NSString *> *> *)uniqueKeys {
    return @[
             @[ al_keypathForClass(TestFileModel, fid) ],
             @[ al_keypathForClass(TestFileModel, basePath), al_keypathForClass(TestFileModel, fileName) ]
             ];
}
//
//+ (void)customDefineColumn:(aldb::Columndef &)cloumn forProperty:(in YYClassPropertyInfo *_Nonnull)property {
//
//}

@end
