//
//  ALDBColumn.m
//  alloy
//
//  Created by Alex Lee on 03/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDBColumn.h"

const ALDBColumn ALDBColumn::s_rowid = ALDBColumn("rowid");
const ALDBColumn ALDBColumn::s_any   = ALDBColumn("*");

ALDBColumn::ALDBColumn(const std::string &name) : _name(name) {}

ALDBColumn::operator std::string() const { return _name; }
std::string ALDBColumn::to_string() const { return _name; }

bool ALDBColumn::operator==(const ALDBColumn &column) const {
    return _name == column._name;
}
