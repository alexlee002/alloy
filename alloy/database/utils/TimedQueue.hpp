//
//  TimedQueue.hpp
//  alloy
//
//  Created by Alex Lee on 31/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#ifndef TimedQueue_hpp
#define TimedQueue_hpp

#include <chrono>
#include <condition_variable>
#include <list>
#include <mutex>
#include <stdio.h>
#include <string>
#include <thread>
#include <unordered_map>

namespace aldb {

template <typename Key>
class TimedQueue {
  public:
    TimedQueue(long long delay_in_milliseconds) : _delay(std::chrono::milliseconds(delay_in_milliseconds)){};

    typedef std::function<void(const Key &)> OnExpired;

    void requeue(const Key &key) {
        std::lock_guard<std::mutex> lockGuard(_mutex);
        bool signal = _list.empty();

        auto iter = _map.find(key);
        if (iter != _map.end()) {
            _list.erase(iter->second);
            _map.erase(iter);
        }
        
        _list.push_front({key, std::chrono::steady_clock::now() + _delay});
        auto last = _list.begin();
        _map.insert({key, last});
        if (signal) {
            _cond.notify_one();
        }
    }

    void wait_until_expired(const OnExpired &onexpired, bool forever = true) {
        {
            std::unique_lock<std::mutex> lockGuard(_mutex);
            while (_list.empty()) {
                if (forever) {
                    _cond.wait(lockGuard);
                } else {
                    return;
                }
            }
        }
        bool got_item = false;
        while (!got_item) {
            Element element;
            Time now = std::chrono::steady_clock::now();
            {
                std::unique_lock<std::mutex> lockGuard(_mutex);
                element = _list.back();
                if (now > element.second) {
                    _list.pop_back();
                    _map.erase(element.first);
                    got_item = true;
                }
            }
            if (got_item) {
                onexpired(element.first);
            } else {
                std::this_thread::sleep_for(element.second - now);
            }
        }
    }

  protected:
    using Time    = std::chrono::steady_clock::time_point;
    using Element = std::pair<Key, Time>;
    using List    = std::list<Element>;
    using Map     = std::unordered_map<Key, typename List::iterator>;

    Map _map;
    List _list;
    std::condition_variable _cond;
    std::mutex _mutex;
    std::chrono::milliseconds _delay;
};
}
#endif /* TimedQueue_hpp */
