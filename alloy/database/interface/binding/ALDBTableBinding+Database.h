//
//  ALDBTableBinding+Database.h
//  alloy
//
//  Created by Alex Lee on 16/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDBTableBinding.h"
#import "sql_create_table.hpp"
#import "sql_create_index.hpp"

NS_ASSUME_NONNULL_BEGIN
@interface ALDBTableBinding (Database)

- (const aldb::SQLCreateTable)statementToCreateTable;

- (const aldb::SQLCreateIndex)statementToCreateIndexOnProperties:(NSArray<NSString *> *)properties isUnique:(BOOL)unique;
@end
NS_ASSUME_NONNULL_END
