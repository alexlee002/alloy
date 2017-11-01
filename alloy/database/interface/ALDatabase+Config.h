//
//  ALDatabase+Config.h
//  alloy
//
//  Created by Alex Lee on 11/09/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDatabase.h"
#import "config.hpp"

@interface ALDatabase (Config)

- (void)setConfig:(const aldb::Config &)config named:(NSString *)name order:(aldb::Configs::Order)order;
- (void)setConfig:(const aldb::Config &)config named:(NSString *)name;

+ (const aldb::Configs &)defaultConfigs;

- (void)configBusyRetryHandler:(int (*)(void *, int))busyHandler;
//- (void)configJournalModel:(NSString *)mode;
//- (void)configLockingModel:(NSString *)mode;
//- (void)configSynchronousModel:(NSString *)mode;
- (void)configCacheSize:(NSInteger)size;
- (void)configPageSize:(NSInteger)size;

@end
