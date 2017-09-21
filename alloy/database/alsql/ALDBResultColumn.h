//
//  ALDBResultColumn.h
//  alloy
//
//  Created by Alex Lee on 20/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALSQLExpr.h"
#import "ALDBColumnProperty.h"
#import "ALSQLClause.h"

class ALDBResultColumn: public ALSQLClause {
public:
    ALDBResultColumn();
    ALDBResultColumn(const ALSQLExpr &expr);
    ALDBResultColumn(const ALDBColumnProperty &property);
    
    ALDBResultColumn &as(const ALDBColumnProperty &property);
    ALDBResultColumn &as(NSString *name);
    
    id column_binding() const;
    
private:
    id _binding;
};

class ALDBResultColumnList : public std::list<const ALDBResultColumn> {
  public:
    ALDBResultColumnList();
    
    template <typename T>
    ALDBResultColumnList(const std::list<const T> &list,
                         typename std::enable_if<std::is_base_of<ALDBResultColumn, T>::value ||
                                                     std::is_base_of<ALDBColumnProperty, T>::value ||
                                                     std::is_base_of<ALSQLExpr, T>::value,
                                                 ALDBResultColumn>::type * = nullptr)
        : std::list<const ALDBResultColumn>(list.begin(), list.end()) {}

    template <typename T>
    ALDBResultColumnList(const T &value,
                         typename std::enable_if<std::is_base_of<ALDBResultColumn, T>::value ||
                                                 std::is_base_of<ALDBColumnProperty, T>::value ||
                                                 std::is_base_of<ALSQLExpr, T>::value>::type * = nullptr)
        : std::list<const ALDBResultColumn>({value}) {}
};
