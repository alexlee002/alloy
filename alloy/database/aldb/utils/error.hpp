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
    
    void log(const char *file, int line) const;

  public:
    const std::string domain;
    const int64_t code;
    const std::string message;
    
    std::string file;
    int line;
};

typedef std::shared_ptr<aldb::Error> ErrorPtr;
    
//class ErrorPtr {
//  public:
//    ErrorPtr();
//    ErrorPtr(const Error &error);
//    ErrorPtr(const std::nullptr_t &);
//    virtual ~ErrorPtr();
//
//    void set_error(const Error &err);
//
//    operator bool() const;
//    bool operator==(const std::nullptr_t &) const;
//    bool operator!=(const std::nullptr_t &) const;
//    ErrorPtr &operator=(const std::nullptr_t &);
//    ErrorPtr &operator=(std::shared_ptr<Error> ptr);
//
//    constexpr Error *operator->() const { return _error.get(); }
//
//  private:
//    bool is_nullptr() const;
//    
//    std::shared_ptr<Error> _error;
//    bool _is_null;
//};
}

#endif /* Error_hpp */
