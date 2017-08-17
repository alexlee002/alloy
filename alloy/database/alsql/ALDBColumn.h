//
//  ALDBColumn.h
//  alloy
//
//  Created by Alex Lee on 03/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <string>

class ALDBColumn {
public:
    static const ALDBColumn s_rowid;
    static const ALDBColumn s_any;
    
    ALDBColumn(const std::string &name);
    
    operator std::string() const;
    std::string to_string() const;
    bool operator==(const ALDBColumn &column) const;
    
protected:
    std::string _name;
};
