//
//  ALDBHandle.h
//  alloy
//
//  Created by Alex Lee on 02/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "core_base.hpp"
#import "sql_statement.hpp"
#import "sql_select.hpp"
#import "ALDBStatement.h"
#import "ALDBResultSet.h"

NS_ASSUME_NONNULL_BEGIN
@interface ALDBHandle : NSObject

@property(nonatomic, nullable, copy, readonly) NSString *path;

@end

@interface ALDBHandle (ALDB_Core)

- (BOOL)exec:(const aldb::SQLStatement &)statement error:(NSError *_Nullable *)error;

- (nullable ALDBResultSet *)query:(const aldb::SQLSelect &)select error:(NSError *_Nullable *)error;

- (nullable ALDBStatement *)prepare:(const aldb::SQLStatement &)statement error:(NSError *_Nullable *)error;

- (BOOL)inTransaction:(void (^)(BOOL *rollback))transaction error:(NSError *_Nullable*)error;

@end

NS_ASSUME_NONNULL_END
