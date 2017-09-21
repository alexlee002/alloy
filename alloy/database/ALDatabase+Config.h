//
//  ALDatabase+Config.h
//  alloy
//
//  Created by Alex Lee on 11/09/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDatabase.h"
#import "config.hpp"


extern NSString * const kALDBDefaultConfigsName;
extern NSString * const kALDBBusyRetryConfigName;
extern NSString * const kALDBJournalModelConfigName;
extern NSString * const kALDBLockingModelConfigName;
extern NSString * const kALDBSynchronousConfigName;

@interface ALDatabase (Config)

+ (const aldb::Configs &)defaultConfigs;

@end
