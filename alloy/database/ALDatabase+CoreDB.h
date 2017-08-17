//
//  ALDatabase+CoreDB.h
//  alloy
//
//  Created by Alex Lee on 28/07/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDatabase.h"
#import "ALDBTypeDefs.h"
#import "ALSQLValue.h"
#import "ALDBResultSet.h"

NS_ASSUME_NONNULL_BEGIN

@interface ALDatabase (CoreDB)

- (BOOL)isOpened;

- (void)setConfig:(const aldb::Config)config named:(NSString *)name ordered:(aldb::Configs::Order)order;
- (void)setConfig:(const aldb::Config)config named:(NSString *)name;

- (BOOL)exec:(NSString *)sql;
- (BOOL)exec:(NSString *)sql args:(const std::list<const ALSQLValue>)args;
- (BOOL)exec:(NSString *)sql arguments:(NSArray<id> *)args;

- (nullable ALDBResultSet *)query:(NSString *)sql;
- (nullable ALDBResultSet *)query:(NSString *)sql args:(const std::list<const ALSQLValue>)args;
- (nullable ALDBResultSet *)query:(NSString *)sql arguments:(NSArray<id> *)args;

- (BOOL)inTransaction:(BOOL (^)(void))transactionBlock
         eventHandler:(void (^_Nullable)(ALDBTransactionEvent event))eventHandler;

//- (BOOL)beginTransaction:(ALDBTransactionMode)mode;
//- (BOOL)commitTransaction;
//- (BOOL)rollbackTransaction;

//bool is_opened() const;
//void close(std::function<void(void)> on_closed);
//
//void set_config(const std::string &name, const Config &config, Configs::Order order);
//void set_config(const std::string &name, const Config &config);
//
//std::shared_ptr<StatementHandle> prepare(const std::string &sql) override;
//bool exec(const std::string &sql) override;
//bool exec(const std::string &sql, const std::list<const SQLValue> &args) override;
//
//bool begin_transaction(const aldb::TransactionMode mode) override;
//bool commit() override;
//bool rollback() override;

@end

NS_ASSUME_NONNULL_END
