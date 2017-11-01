//
//  ALDBResultColumn.h
//  alloy
//
//  Created by Alex Lee on 07/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//
//  Fork from WCDB, github: https://github.com/tencent/wcdb
//

#import <Foundation/Foundation.h>
#import "column_result.hpp"
#import "ALDBCodingMacros_Private.h"

class ALDBResultColumnList;
class ALDBProperty;
class ALDBExpr;
class ALDBResultColumn : public aldb::ResultColumn {
    __ALDB_PROPERTY_BASE_DEF;

  public:
    ALDBResultColumn(const ALDBExpr &expr);
    ALDBResultColumn(const ALDBProperty &property);

    ALDBResultColumn &as(const ALDBProperty &property);

    ALDBResultColumnList distinct() const;
    
    NSString *description() const;
};


class ALDBPropertyList;
class ALDBResultColumnList : public std::list<const ALDBResultColumn> {
  public:
    ALDBResultColumnList();

    template <typename T = ALDBResultColumn>
    ALDBResultColumnList(const T &value,
                         typename std::enable_if<std::is_constructible<ALDBResultColumn, T>::value>::type * = nullptr)
        : std::list<const ALDBResultColumn>({ALDBResultColumn(value)})
        , _distinct(false) {}

    ALDBResultColumnList(std::initializer_list<const ALDBExpr> list);
    ALDBResultColumnList(std::initializer_list<const ALDBProperty> list);

    ALDBResultColumnList(const ALDBPropertyList &propertyList);
    ALDBResultColumnList(const std::list<const ALDBExpr> &exprList);

    ALDBResultColumnList(std::initializer_list<const ALDBPropertyList> list);

    ALDBResultColumnList &distinct();

    bool isDistinct() const;

  protected:
    bool _distinct;
};
