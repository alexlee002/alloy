//
//  TestFileModel.h
//  alloyTests
//
//  Created by Alex Lee on 13/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALActiveRecord.h"

@protocol TestFileModelProtocol <NSObject>
@property(nonatomic, assign)    NSInteger   fid;
@property(nonatomic, assign)    NSInteger   size;
@property(nonatomic, copy)      NSString    *fileName;
@property(nonatomic, copy)      NSString    *basePath;
@property(nonatomic, strong)    NSDate      *mtime;
@property(nonatomic, strong)    NSDate      *ctime;
@end

@interface TestFileModel : NSObject <TestFileModelProtocol, ALActiveRecord>
@end

