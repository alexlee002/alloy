//
//  ALDBMigrationHelper.h
//  alloy
//
//  Created by Alex Lee on 27/07/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#ifdef __cplusplus
#import <Foundation/Foundation.h>
#import "handle_recyclable.hpp"

@interface ALDBMigrationHelper : NSObject

+ (BOOL)setupDatabaseUsingHandle:(const aldb::RecyclableHandle &)handle;
+ (BOOL)autoMigrateDatabaseUsingHandle:(const aldb::RecyclableHandle &)handle;

@end

#endif
