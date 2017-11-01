//
//  console_logger.cpp
//  alloy
//
//  Created by Alex Lee on 28/09/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#include "console_logger.hpp"
#include <pthread/pthread.h>
#include <ctime>   // localtime
#include <sstream> // stringstream
#include <iomanip> // put_time
#include <libgen.h>

namespace aldb {

#pragma mark - util functions

static inline void write_timestamp(std::stringstream &os, std::chrono::system_clock::time_point tp) {
    auto tp_duration = std::chrono::duration_cast<std::chrono::milliseconds>(tp.time_since_epoch()).count();
    std::time_t tp_time_t = std::chrono::system_clock::to_time_t(tp);
    os << "[" << std::put_time(std::localtime(&tp_time_t), "%T.") << (tp_duration % 1000) << "]";
}

static inline void write_log_level(std::stringstream &os, ConsoleLogger::Level level) {
    switch (level) {
        case ConsoleLogger::Level::VERBOSE:    os << " 👾 "; break;
        case ConsoleLogger::Level::INFO:       os << " ✅ "; break;
        case ConsoleLogger::Level::WARN:       os << " ⚠️ "; break;
        case ConsoleLogger::Level::ERROR:      os << " ❌ "; break;
        default:                               os << " ❓ ";
            break;
    }
}

static inline void write_thread_ctx(std::stringstream &os) {
    __uint64_t thread_id;
    pthread_threadid_np(NULL, &thread_id);
    os << "[" << thread_id;
    
    if (pthread_main_np() != 0) {
        os << "(main)";
    }
    os << "]";
}

static inline std::string formated_msg(const char *format, va_list args) {
    va_list cpy_args;
    va_copy(cpy_args, args);

    std::unique_ptr<char[]> buf = nullptr;
    int actual_size = vsnprintf(0, 0, format, args);
    if (actual_size >= 0) {
        buf.reset(new char[actual_size + 1]());
        vsnprintf(buf.get(), actual_size + 1, format, cpy_args);
    }
    va_end(cpy_args);
    return buf ? buf.get() : "";
}

#pragma mark - ConsoleLogger
ConsoleLogger::Level ConsoleLogger::s_level = aldb::ConsoleLogger::Level::VERBOSE;

void ConsoleLogger::write(std::chrono::system_clock::time_point tp, __uint64_t threadid, bool main_thread,
                          const char *file, int line, const char *func, const char *tag, Level level,
                          const std::string &message) {
    if (level < s_level) {
        return;
    }

    std::stringstream os;

    write_timestamp(os, tp);
    write_log_level(os, level);

    {
        os << "[" << threadid;
        if (main_thread) {
            os << "(main)";
        }
        os << "]";
    }

    if (tag && strlen(tag) > 0) {
        os << "[" << tag << "]";
    }

    if (func && strlen(func) > 0) {
        os << " " << func;
    }

    if (file && strlen(file) > 0) {
        os << "(" << basename((char *) file) << ": " << line << ")";
    }

    os << " 👉🏻 " << message;
    std::printf("%s\n", os.str().c_str());
}

void ConsoleLogger::write(const char *file, int line, const char *func, const char *tag, Level level,
                          const char *format, ...) {
    if (level < aldb::ConsoleLogger::s_level) {
        return;
    }

    {
        __uint64_t threadid;
        pthread_threadid_np(NULL, &threadid);

        va_list args;
        va_start(args, format);
        std::string message = formated_msg(format, args);
        va_end(args);

        write(std::chrono::system_clock::now(), threadid, pthread_main_np() != 0, file, line, func, tag, level, message);
    }
}
}
