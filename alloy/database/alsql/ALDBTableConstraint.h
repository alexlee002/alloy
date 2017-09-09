//
//  ALDBTableConstraint.h
//  alloy
//
//  Created by Alex Lee on 27/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <string>
#import "ALDBIndexedColumn.h"
#import "ALSQLClause.h"

class ALDBTableConstraint: public ALSQLClause {
public:
    ALDBTableConstraint();
    ALDBTableConstraint(const char *name);
    ALDBTableConstraint(const std::string &name);

    ALDBTableConstraint &primary_key(const std::list<const ALDBIndexedColumn> &columns,
                                     ALDBConflictPolicy on_conflict = ALDBConflictPolicyDefault);

    ALDBTableConstraint &unique(const std::list<const ALDBIndexedColumn> &columns,
                                ALDBConflictPolicy on_conflict = ALDBConflictPolicyDefault);
    
    ALDBTableConstraint &check(const ALSQLExpr &expr);
};
