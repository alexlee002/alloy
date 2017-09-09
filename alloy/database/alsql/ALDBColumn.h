
//
//  ALDBColumn.h
//  alloy
//
//  Created by Alex Lee on 03/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <string>
#import <list>

class ALDBColumn {
public:
    static const ALDBColumn s_rowid;
    static const ALDBColumn s_any;
    
    ALDBColumn(const std::string &name);
    ALDBColumn(NSString *name);
    ALDBColumn(const char *name);
    
    ALDBColumn in_table(const std::string &name) const;
    
    operator std::string() const;
    const std::string to_string() const;
    bool operator==(const ALDBColumn &column) const;
    
protected:
    std::string _name;
};

class ALDBColumnList : public std::list<const ALDBColumn> {
  public:
    template <typename T>
    ALDBColumnList(const std::list<const T> &list,
                   typename std::enable_if<std::is_base_of<ALDBColumn, T>::value>::type * = nullptr)
        : std::list<const ALDBColumn>(list.begin(), list.end()) {}
};
;
