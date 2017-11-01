//
//  ALDBHandle.m
//  alloy
//
//  Created by Alex Lee on 02/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDBHandle.h"
#import "ALDBHandle_Private.h"
#import "NSError+ALDBError.h"
#import "ALDBStatement_Private.h"

@implementation ALDBHandle

+ (instancetype)handleWithCore:(const std::shared_ptr<aldb::CoreBase> &)core {
    ALDBHandle *handle = [[self alloc] init];
    handle->_coreHandle = core;
    return handle;
}

- (NSString *)path {
    return @(_coreHandle->get_path().c_str());
}

- (BOOL)exec:(const aldb::SQLStatement &)stmt error:(NSError *_Nullable *)error {
    aldb::ErrorPtr err;
    BOOL ret = _coreHandle->exec(stmt.sql(), stmt.values(), err);
    if (!ret && error && err) {
        *error = [NSError errorWithALDBError:*err];
    }
    return ret;
}

- (nullable ALDBResultSet *)query:(const aldb::SQLSelect &)select error:(NSError *_Nullable *)error {
    ALDBStatement *stmt = [self prepare:select error:error];
    if (stmt) {
        ALDBResultSet *rs = [stmt query:select.values()];
        if (!rs && [stmt hasError] && error) {
            *error = [stmt lastError];
            return nil;
        }
        return rs;
    }
    return nil;
}

- (nullable ALDBStatement *)prepare:(const aldb::SQLStatement &)statement error:(NSError *_Nullable *)error {
    aldb::ErrorPtr err;
    auto pstmt = _coreHandle->prepare(statement.sql(), err);
    if (!pstmt && error && err) {
        *error = [NSError errorWithALDBError:*err];
    }
    return [[ALDBStatement alloc] initWithCoreStatementHandle:pstmt
                                                 SQLStatement:std::make_shared<aldb::SQLStatement>(statement)];
}

@end
