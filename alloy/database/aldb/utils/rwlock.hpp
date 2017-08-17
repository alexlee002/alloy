//
//  rwlock.hpp
//  alloy
//
//  Created by Alex Lee on 24/07/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#ifndef rwlock_hpp
#define rwlock_hpp

#include <stdio.h>
#include <mutex>
#include <condition_variable>

namespace aldb {

//@link:
//https://stackoverflow.com/questions/27860685/how-to-make-a-multiple-read-single-write-lock-from-more-basic-synchronization-pr
class RWLock {
  public:
    RWLock();
    //        virtual ~RWLock();

    void lock_read();
    void unlock_read();
    bool reading() const;

    void lock_write();
    void unlock_write();
    bool writing() const;

  private:
    mutable std::mutex _shared_mutex;
    std::condition_variable _rcond;
    std::condition_variable _wcond;

    size_t _active_readers;
    size_t _waiting_writers;
    size_t _active_writers;
};
}

#endif /* rwlock_hpp */
