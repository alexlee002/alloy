//
//  ALDBMigrationHelper.h
//  alloy
//
//  Created by Alex Lee on 27/07/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#ifdef __cplusplus
#import <Foundation/Foundation.h>
#import "handle.hpp"

@interface ALDBMigrationHelper : NSObject

+ (BOOL)setupDatabaseUsingHandle:(std::shared_ptr<aldb::Handle> &)handle;
+ (BOOL)autoMigrateDatabaseUsingHandle:(std::shared_ptr<aldb::Handle> &)handle;

@end

#endif
