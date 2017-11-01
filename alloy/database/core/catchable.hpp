//
//  catchable.hpp
//  alloy
//
//  Created by Alex Lee on 01/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#ifndef catchable_hpp
#define catchable_hpp

#include <stdio.h>
#include "error.hpp"
#include <sqlite3.h>


namespace aldb {
class Catchable {
  public:
    std::shared_ptr<aldb::Error> get_error() const;
    bool has_error() const;
    
    void log_error(const char *file, int line) const;

  protected:
    Catchable();
    void reset_error();
    void set_error(const Error &error);
    void retain_error(const std::shared_ptr<Error> error);

    void set_sqlite_error(sqlite3 *h, const char *sql = NULL);
    void set_aldb_error(int code, const char *message);

  private:
    std::shared_ptr<aldb::Error> _error;
};
}

#endif /* catchable_hpp */
