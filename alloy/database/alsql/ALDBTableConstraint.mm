//
//  ALDBTableConstraint.m
//  alloy
//
//  Created by Alex Lee on 27/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDBTableConstraint.h"
#import "ALSQLValue.h"

ALDBTableConstraint::ALDBTableConstraint() : ALSQLClause() {}

ALDBTableConstraint::ALDBTableConstraint(const char *name) : ALSQLClause(std::string("CONSTRAINT ") + (name ?: "")) {}
ALDBTableConstraint::ALDBTableConstraint(const std::string &name) : ALSQLClause("CONSTRAINT " + name) {}

ALDBTableConstraint &ALDBTableConstraint::primary_key(const std::list<const ALDBIndexedColumn> &columns,
                                                      ALDBConflictPolicy on_conflict) {
    ALSQLClause::append(" PRIMARY KEY (")
        .append(ALSQLClause::combine<ALSQLClause, ALDBIndexedColumn>(columns, ", "))
        .append(")");
    if (on_conflict != ALDBConflictPolicyDefault) {
        ALSQLClause::append(" ON CONFLICT ").append(aldb::conflict_term((aldb::ConflictPolicy) on_conflict));
    }
    return *this;
}

ALDBTableConstraint &ALDBTableConstraint::unique(const std::list<const ALDBIndexedColumn> &columns,
                                                 ALDBConflictPolicy on_conflict) {
    ALSQLClause::append(" UNIQUE ").append(ALSQLClause::combine<ALSQLClause, ALDBIndexedColumn>(columns, ", "));
    if (on_conflict != ALDBConflictPolicyDefault) {
        ALSQLClause::append(" ON CONFLICT ").append(aldb::conflict_term((aldb::ConflictPolicy) on_conflict));
    }
    return *this;
}

ALDBTableConstraint &ALDBTableConstraint::check(const ALSQLExpr &expr) {
    ALSQLClause::append(" CHECK (").append(expr).append(")");
    return *this;
}
