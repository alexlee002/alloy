//
//  gcd_lock_guard.hpp
//  alloy
//
//  Created by Alex Lee on 24/07/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#ifndef gcd_lock_guard_hpp
#define gcd_lock_guard_hpp

#include <stdio.h>
#include <dispatch/dispatch.h>

namespace aldb {
class GCDLockGuard {
  public:
    GCDLockGuard(dispatch_semaphore_t dsem, dispatch_time_t timeout = DISPATCH_TIME_FOREVER) : _dsem(dsem) {
        dispatch_semaphore_wait(_dsem, timeout);
    }

    virtual ~GCDLockGuard() { dispatch_semaphore_signal(_dsem); }

  private:
    dispatch_semaphore_t _dsem;
};
}

#endif /* gcd_lock_guard_hpp */
