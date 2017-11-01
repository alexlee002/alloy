
//
//  rwlock.cpp
//  alloy
//
//  Created by Alex Lee on 24/07/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#include "rwlock.hpp"

namespace aldb {
RWLock::RWLock() : _shared_mutex(), _rcond(), _wcond(), _active_readers(0), _waiting_writers(0), _active_writers(0) {}
//    virtual ~RWLock();

void RWLock::lock_read() {
    std::unique_lock<std::mutex> lock(_shared_mutex);
    while (_waiting_writers != 0) {
        _rcond.wait(lock);
    }
    ++_active_readers;
    lock.unlock();
}

void RWLock::unlock_read() {
    std::unique_lock<std::mutex> lock(_shared_mutex);
    --_active_readers;
    lock.unlock();
    _wcond.notify_one();
}

void RWLock::lock_write() {
    std::unique_lock<std::mutex> lock(_shared_mutex);
    ++_waiting_writers;
    while (_active_readers != 0 || _active_writers != 0) {
        _wcond.wait(lock);
    }
    ++_active_writers;
    lock.unlock();
}

void RWLock::unlock_write() {
    std::unique_lock<std::mutex> lock(_shared_mutex);
    --_waiting_writers;
    --_active_writers;
    if (_waiting_writers > 0) {
        _wcond.notify_one();
    } else {
        _rcond.notify_all();
    }
    lock.unlock();
}

bool RWLock::reading() const {
    std::unique_lock<std::mutex> lock(_shared_mutex);
    return _active_readers > 0;
}

bool RWLock::writing() const {
    std::unique_lock<std::mutex> lock(_shared_mutex);
    return _active_writers > 0;
}
}
