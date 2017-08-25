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
