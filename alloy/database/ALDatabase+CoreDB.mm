//
//  ALDatabase+CoreDB.m
//  alloy
//
//  Created by Alex Lee on 28/07/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDatabase+CoreDB.h"
#import "__ALDatabase+private.h"
#import "ALUtilitiesHeader.h"
#import "ALLogger.h"
#import "ALOCRuntime.h"

#ifdef DEBUG
#define DEBUG_LOG_DB_ERROR()                                                  \
    if ([self _coreDB]->has_error()) {                                        \
        ALLogError(@"%s", std::string(*[self _coreDB]->get_error()).c_str()); \
    }
#else
#define DEBUG_LOG_DB_ERROR() do {} while (0)
#endif

@implementation ALDatabase (CoreDB)

- (BOOL)isOpened {
    return [self _coreDB]->is_opened();
}

- (void)setConfig:(const aldb::Config)config
            named:(NSString *)name
          ordered:(aldb::Configs::Order)order {
    [self _coreDB]->set_config(name.UTF8String, config, order);
    DEBUG_LOG_DB_ERROR();
}

- (void)setConfig:(const aldb::Config)config named:(NSString *)name {
    [self _coreDB]->set_config(name.UTF8String, config);
    DEBUG_LOG_DB_ERROR();
}

- (void)cacheStatementForSQL:(NSString *)sql {
    [self _coreDB]->cache_statement_for_sql(sql.UTF8String);
}

- (BOOL)exec:(NSString *)sql {
    BOOL ret = [self _coreDB]->exec(sql.UTF8String);
    DEBUG_LOG_DB_ERROR();
    return ret;
}

- (BOOL)exec:(NSString *)sql args:(const std::list<const ALSQLValue>)args {
    if (args.empty()) {
        return [self exec:sql];
    }
    
    std::list<const aldb::SQLValue> coreValues;
    for (auto arg : args) {
        coreValues.push_back(arg);
    }
    BOOL ret = [self _coreDB]->exec(sql.UTF8String, coreValues);
    DEBUG_LOG_DB_ERROR();
    return ret;
}

- (BOOL)exec:(NSString *)sql arguments:(NSArray<id> *)args {
    if (args.count == 0) {
        return [self exec:sql];
    }
    
    std::list<const aldb::SQLValue> coreValues;
    for (id arg in args) {
        coreValues.push_back(ALSQLValue(arg));
    }
    BOOL ret = [self _coreDB]->exec(sql.UTF8String, coreValues);
    DEBUG_LOG_DB_ERROR();
    return ret;
}

- (nullable ALDBResultSet *)query:(NSString *)sql {
    aldb::RecyclableStatement stmt = [self _coreDB]->prepare(sql.UTF8String);
    if (stmt) {
        return [ALDBResultSet resultSetWithStatement:stmt];
    }
    
    DEBUG_LOG_DB_ERROR();
    return nil;
}

- (nullable ALDBResultSet *)query:(NSString *)sql args:(const std::list<const ALSQLValue>)args {
    aldb::RecyclableStatement stmt = [self _coreDB]->prepare(sql.UTF8String);
    if (stmt) {
        int idx = 1;
        for (auto v : args) {
            stmt->bind_value(v, idx);
            idx++;
        }
        return [ALDBResultSet resultSetWithStatement:stmt];
    }
    
    DEBUG_LOG_DB_ERROR();
    return nil;
}

- (nullable ALDBResultSet *)query:(NSString *)sql arguments:(NSArray<id> *)args {
    aldb::RecyclableStatement stmt = [self _coreDB]->prepare(sql.UTF8String);
    if (stmt) {
        int idx = 1;
        for (id v in args) {
            stmt->bind_value(ALSQLValue(v), idx);
            idx++;
        }
        return [ALDBResultSet resultSetWithStatement:stmt];
    }
   
    DEBUG_LOG_DB_ERROR();
    return nil;
}

- (BOOL)inTransaction:(void (^)(BOOL *rollback))transactionBlock
         eventHandler:(void (^)(ALDBTransactionEvent event))eventHandler {
    if (transactionBlock == nil) {
        return NO;
    }
    
    aldb::CoreBase::TransactionEventBlock eventBlock = nullptr;
    if (eventHandler) {
        eventBlock = [&eventHandler](aldb::CoreBase::TransactionEvent event) {
#if DEBUG
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
#endif
            ALSafeInvokeBlock(eventHandler, (ALDBTransactionEvent)event);
        };
    }
    
    return [self _coreDB]->exec_transaction([&transactionBlock](bool &rollback) {
        transactionBlock(&rollback);
    },  eventBlock);
}

@end
