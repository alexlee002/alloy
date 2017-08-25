//
//  ALDBResultColumn.m
//  alloy
//
//  Created by Alex Lee on 20/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDBResultColumn.h"
#import "ALSQLValue.h"

ALDBResultColumn::ALDBResultColumn():ALSQLClause() {}
ALDBResultColumn::ALDBResultColumn(const ALSQLExpr &expr) : ALSQLClause(expr), _binding(nil) {}

id ALDBResultColumn::column_binding() const { return _binding; }

ALDBResultColumn::ALDBResultColumn(const ALDBColumnProperty &property)
    : ALSQLClause(property), _binding(property.column_binding()){};

ALDBResultColumn &ALDBResultColumn::as(const ALDBColumnProperty &property) {
    ALSQLClause::append(" AS " + property.name());
    _binding = property.column_binding();
    return *this;
}

ALDBResultColumn &ALDBResultColumn::as(NSString *name) {
    ALSQLClause::append(" AS ");
    ALSQLClause::append(name.UTF8String);
    return *this;
}
