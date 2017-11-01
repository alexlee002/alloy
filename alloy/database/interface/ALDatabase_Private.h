//
//  ALDatabase_Private.h
//  alloy
//
//  Created by Alex Lee on 04/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDatabase.h"
#import "database.hpp"

@interface ALDatabase () {
@protected
    std::shared_ptr<aldb::Database> _coreDatabase;
}

@end
