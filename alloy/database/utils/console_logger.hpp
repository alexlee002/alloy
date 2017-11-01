//
//  console_logger.hpp
//  alloy
//
//  Created by Alex Lee on 28/09/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#ifndef console_logger_hpp
#define console_logger_hpp

#include <stdio.h>
#include <chrono>  // chrono::system_clock
#include <string>

namespace aldb {
class ConsoleLogger {
  public:
    enum class Level : int { VERBOSE, INFO, WARN, ERROR };

    static Level s_level;

    static void write(std::chrono::system_clock::time_point tp, __uint64_t threadid, bool main_thread, const char *file,
                      int line, const char *func, const char *tag, Level level, const std::string &message);

    static void write(const char *file, int line, const char *func, const char *tag, Level level, const char *format,
                      ...);
};
}

#endif /* console_logger_hpp */
