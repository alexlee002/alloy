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

namespace aldb {
class Error {
  public:
    Error(const std::string &domain, int64_t code, const char *message = nullptr);

    Error(const Error &other);

    operator std::string() const;
    const std::string description() const;
    
  public:
    const std::string domain;
    const int64_t code;
    const std::string message;
    
    std::string file;
    int line;
};

typedef std::shared_ptr<aldb::Error> ErrorPtr;

}

#endif /* Error_hpp */
