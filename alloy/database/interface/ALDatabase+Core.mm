//
//  ALDatabase+Core.m
//  alloy
//
//  Created by Alex Lee on 11/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDatabase+Core.h"
#import "ALDatabase_Private.h"
#import "ALLogger.h"
#import "core_base.hpp"
#import "ALOCRuntime.h"
#import "NSError+ALDBError.h"

@implementation ALDatabase (Core)

- (BOOL)inTransaction:(void (^)(BOOL * _Nonnull))transaction error:(NSError *__autoreleasing  _Nullable *)error {
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

            default:
                break;
        }
        ALLogWarn(@"transaction doesn't commit! event:%@\ncall stack:\n%@", eventMsg, al_backtraceStack(15));
    };
#else
    aldb::CoreBase::TransactionEventBlock eventBlock = nullptr;
#endif

    aldb::ErrorPtr err;
    BOOL result =
        _coreDatabase->exec_transaction([&transaction](bool &rollback) { transaction(&rollback); }, eventBlock, err);
    if (!result && error && err) {
        *error = [NSError errorWithALDBError:*err];
    }
    return result;
}

@end
