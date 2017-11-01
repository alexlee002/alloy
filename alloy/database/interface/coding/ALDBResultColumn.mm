//
//  ALDBResultColumn.m
//  alloy
//
//  Created by Alex Lee on 07/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDBResultColumn.h"
#import "ALDBExpr.h"
#import "ALDBProperty.h"

#pragma mark - ALDBResultColumn

__ALDB_PROPERTY_BASE_IMP(ALDBResultColumn);

ALDBResultColumn::ALDBResultColumn(const ALDBExpr &expr)
    : aldb::ResultColumn(expr), __ALDB_PROPERTY_BASE_CTOR1(expr) {
}
ALDBResultColumn::ALDBResultColumn(const ALDBProperty &property)
    : aldb::ResultColumn(property), __ALDB_PROPERTY_BASE_CTOR1(property) {
}

ALDBResultColumn &ALDBResultColumn::as(const ALDBProperty &property) {
    aldb::ResultColumn::as(property.name());
    setBinding(__ALDB_CAST_PROPERTY(property));
    return *this;
}

ALDBResultColumnList ALDBResultColumn::distinct() const {
    return ALDBResultColumnList(*this).distinct();
}

NSString *ALDBResultColumn::description() const {
    return @(aldb::ResultColumn::sql().c_str());
}

#pragma mark - ALDBResultColumnList

ALDBResultColumnList::ALDBResultColumnList() : std::list<const ALDBResultColumn>(), _distinct(false) {
}

ALDBResultColumnList::ALDBResultColumnList(std::initializer_list<const ALDBExpr> list)
    : std::list<const ALDBResultColumn>(list.begin(), list.end()), _distinct(false) {
}

ALDBResultColumnList::ALDBResultColumnList(std::initializer_list<const ALDBProperty> list)
    : std::list<const ALDBResultColumn>(list.begin(), list.end()), _distinct(false) {
}

ALDBResultColumnList::ALDBResultColumnList(const ALDBPropertyList &list)
    : std::list<const ALDBResultColumn>(list.begin(), list.end()), _distinct(false) {
}

ALDBResultColumnList::ALDBResultColumnList(const std::list<const ALDBExpr> &list)
    : std::list<const ALDBResultColumn>(list.begin(), list.end()), _distinct(false) {
}

ALDBResultColumnList::ALDBResultColumnList(std::initializer_list<const ALDBPropertyList> list)
    : std::list<const ALDBResultColumn>(), _distinct(false) {
    for (const auto &pl : list) {
        for (const auto &property : pl) {
            push_back(property);
        }
    }
}

ALDBResultColumnList &ALDBResultColumnList::distinct() {
    _distinct = true;
    return *this;
}

bool ALDBResultColumnList::isDistinct() const {
    return _distinct;
}
