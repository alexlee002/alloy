//
//  ALDBConnectionDelegate.h
//  alloy
//
//  Created by Alex Lee on 27/07/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "handle.hpp"

@class ALDatabase;
@protocol ALDBConnectionDelegate <NSObject>

@required
+ (BOOL)canOpenDatabaseWithPath:(nonnull in NSString *)path;

@optional
- (void)databaseDidOpen:(std::shared_ptr<aldb::Handle> &)handle;
- (void)databaseDidReady:(std::shared_ptr<aldb::Handle> &)handle;

- (void)willCloseDatabase:(ALDatabase *_Nonnull)database;
- (void)didCloseDatabase:(ALDatabase *_Nonnull)database;

@end
