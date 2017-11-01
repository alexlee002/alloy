//
//  macros.h
//  alloy
//
//  Created by Alex Lee on 28/09/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#ifndef macros_h
#define macros_h

#include <pthread/pthread.h>
#include "console_logger.hpp"

#define __AL_DUMMY_MACRO do {} while(0)

#if DEBUG

#define __ALDB_CHECK_THREAD(tid)                                                                                     \
    __uint64_t threadid;                                                                                             \
    pthread_threadid_np(NULL, &threadid);                                                                            \
    if ((tid) != threadid) {                                                                                         \
        ALDB_ERROR("The resource can not be accessed in multi-thread mode! owner thread: %llu, access: %llu", (tid), \
                   threadid);                                                                                        \
        abort();                                                                                                     \
    }
#define __ALDB_CURRENT_THREAD_ID()            \
    ({                                        \
        __uint64_t threadid;                  \
        pthread_threadid_np(NULL, &threadid); \
        threadid;                             \
    })

#define __ALDB_LOG(level, fmt, ...) \
    aldb::ConsoleLogger::write(__FILE__, __LINE__, __FUNCTION__, "ALDB", level, fmt, ##__VA_ARGS__)

#define ALDB_DEBUG(fmt, ...)    __ALDB_LOG(aldb::ConsoleLogger::Level::VERBOSE, fmt, ##__VA_ARGS__)
#define ALDB_INFO(fmt, ...)     __ALDB_LOG(aldb::ConsoleLogger::Level::INFO,    fmt, ##__VA_ARGS__)
#define ALDB_WARN(fmt, ...)     __ALDB_LOG(aldb::ConsoleLogger::Level::WARN,    fmt, ##__VA_ARGS__)
#define ALDB_ERROR(fmt, ...)    __ALDB_LOG(aldb::ConsoleLogger::Level::ERROR,   fmt, ##__VA_ARGS__)

#else

#define __ALDB_CHECK_THREAD(tid)    __AL_DUMMY_MACRO
#define __ALDB_CURRENT_THREAD_ID()  __AL_DUMMY_MACRO

#define ALDB_DEBUG(fmt, ...)     __AL_DUMMY_MACRO
#define ALDB_INFO(fmt, ...)      __AL_DUMMY_MACRO
#define ALDB_WARN(fmt, ...)      __AL_DUMMY_MACRO
#define ALDB_ERROR(fmt, ...)     __AL_DUMMY_MACRO

#endif

#endif /* macros_h */
