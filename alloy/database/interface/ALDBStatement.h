//
//  ALDBStatement.h
//  alloy
//
//  Created by Alex Lee on 02/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALDBResultSet.h"

NS_ASSUME_NONNULL_BEGIN

@interface ALDBStatement : NSObject

- (BOOL)hasError;
- (nullable NSError *)lastError;

- (BOOL)exec;
- (nullable ALDBResultSet *)query;
- (BOOL)execWithValues:(nullable NSArray *)values;
- (nullable ALDBResultSet *)queryWithValues:(nullable NSArray *)values;

- (NSInteger)lastInsertRowId;
- (NSInteger)changes;

- (BOOL)resetBindings;
- (BOOL)bindObject:(nullable id)value atIndex:(NSInteger)index;

- (nullable NSString *)sql;
- (nullable NSString *)expandedSQL;

@end

NS_ASSUME_NONNULL_END

#ifdef __cplusplus
@interface ALDBStatement (CXX_Interface)
- (bool)bindValue:(const aldb::SQLValue &)value atIndex:(int)index;
- (bool)exec:(const std::list<const aldb::SQLValue> &)values;
- (nullable ALDBResultSet *)query:(const std::list<const aldb::SQLValue> &)values;
@end
#endif
