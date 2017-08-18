//
//  Error.hpp
//  alloy
//
//  Created by Alex Lee on 31/07/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#ifndef error_hpp
#define error_hpp

#include <stdio.h>
#include <string>

#ifdef DEBUG
#define ALDB_DEBUG_LOG(error_ref) (error_ref).log()
#else
#define ALDB_DEBUG_LOG(error_ref) do{}while(0)
#endif

namespace aldb {
class Error {
  public:
    Error(const std::string &domain, int64_t code, const char *message = nullptr);

    Error(const Error &other);

    operator std::string() const;
    
    void log(const char *file, int line) const;

  public:
    const std::string domain;
    const int64_t code;
    const std::string message;
    
    std::string file;
    int line;
};
}

#endif /* Error_hpp */
