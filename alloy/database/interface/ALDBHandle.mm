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
#import "ALOCRuntime.h"
#import "ALLogger.h"

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

- (BOOL)inTransaction:(void (^)(BOOL *_Nonnull))transaction error:(NSError *__autoreleasing _Nullable *)error {
    if (transaction == nil) {
        return NO;
    }

#if DEBUG
    aldb::CoreBase::TransactionEventBlock eventBlock = [](aldb::CoreBase::TransactionEvent event) {
        NSString *eventMsg = @"UNKNOWN";
        switch (event) {
            case aldb::CoreBase::TransactionEvent::BEGIN_FAILED:
                eventMsg = @"BEGIN_FAILED";
                break;
            case aldb::CoreBase::TransactionEvent::COMMIT_FAILED:
                eventMsg = @"COMMIT_FAILED";
                break;
            case aldb::CoreBase::TransactionEvent::ROLLBACK:
                eventMsg = @"ROLLBACK";
                break;
            case aldb::CoreBase::TransactionEvent::ROLLBACK_FAILED:
                eventMsg = @"ROLLBACK_FAILED";
                break;
        }
        ALLogWarn(@"transaction doesn't commit! event:%@\ncall stack:\n%@", eventMsg, al_backtraceStack(15));
    };
#else
    aldb::CoreBase::TransactionEventBlock eventBlock = nullptr;
#endif

    aldb::ErrorPtr err;
    BOOL result =
        _coreHandle->exec_transaction([&transaction](bool &rollback) { transaction(&rollback); }, eventBlock, err);
    if (!result && error && err) {
        *error = [NSError errorWithALDBError:*err];
    }
    return result;
}

@end
