//
//  ALDBStatement_Private.h
//  alloy
//
//  Created by Alex Lee on 02/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDBStatement.h"
#import "statement_recyclable.hpp"
#import "sql_statement.hpp"

@interface ALDBStatement () {
    aldb::RecyclableStatement _coreStmtHandle;
    std::shared_ptr<aldb::SQLStatement> _sqlStmt;
}

- (instancetype)initWithCoreStatementHandle:(aldb::RecyclableStatement &)coreStmtHandle
                               SQLStatement:(const std::shared_ptr<aldb::SQLStatement>)sqlstmt;

@end
