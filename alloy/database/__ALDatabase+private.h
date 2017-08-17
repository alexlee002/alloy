//
//  __ALDatabase+private.h
//  alloy
//
//  Created by Alex Lee on 28/07/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#ifndef __ALDatabase_private_h
#define __ALDatabase_private_h

#import <Foundation/Foundation.h>
#import "ALDatabase.h"
#import "database.hpp"

@interface ALDatabase (__Private)

- (std::shared_ptr<aldb::Database> &)_coreDB;

@end

#endif /* __ALDatabase_private_h */
