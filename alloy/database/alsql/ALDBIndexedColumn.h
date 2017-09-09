//
//  ALDBIndexedColumn.h
//  alloy
//
//  Created by Alex Lee on 27/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALDBColumn.h"
#import "ALDBTypeDefs.h"
#import "ALSQLClause.h"
#import "ALSQLExpr.h"

class ALDBIndexedColumn: public ALSQLClause {
public:
    ALDBIndexedColumn();
    ALDBIndexedColumn(const ALDBColumn &column, const char *collate = nullptr, ALDBOrder order = ALDBOrderDefault);
    ALDBIndexedColumn(const ALSQLExpr &expr, const char *collate = nullptr, ALDBOrder order = ALDBOrderDefault);
    
private:
};
