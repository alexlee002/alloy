//
//  ALDatabaseManager.h
//  patchwork
//
//  Created by Alex Lee on 2/18/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Singleton_Template.h"

NS_ASSUME_NONNULL_BEGIN

@class ALDatabase;
@interface ALDatabaseManager : NSObject
AS_SINGLETON

- (nullable ALDatabase *)databaseWithPath:(NSString *)filePath;

@end

NS_ASSUME_NONNULL_END
