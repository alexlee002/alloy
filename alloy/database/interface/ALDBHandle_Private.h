//
//  ALDBHandle_Private.h
//  alloy
//
//  Created by Alex Lee on 02/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDBHandle.h"
#import "core_base.hpp"

@interface ALDBHandle () {
  @protected
    std::shared_ptr<aldb::CoreBase> _coreHandle;
}

+ (instancetype)handleWithCore:(const std::shared_ptr<aldb::CoreBase> &)core;
@end
