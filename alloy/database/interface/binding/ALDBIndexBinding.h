//
//  ALDBIndexBinding.h
//  alloy
//
//  Created by Alex Lee on 17/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALDBTypeDefines.h"
#import "sql_create_index.hpp"

NS_ASSUME_NONNULL_BEGIN

@interface ALDBIndexBinding : NSObject
@property(nonatomic, copy, readonly)  NSString   *table;
@property(nonatomic,       readonly)  BOOL        unique;
@property(nonatomic, copy, nullable)  NSString   *indexName;

+ (instancetype)indexBindingWithTableName:(NSString *)tableName isUnique:(BOOL)unique;

- (void)addIndexColumn:(const ALDBIndex &)column;
- (void)setCondition:(const ALDBCondition &)condition;

- (const std::list<const ALDBIndex> &)indexColumns;
- (const ALDBCondition &)condition;

- (aldb::SQLCreateIndex)indexCreationStatement;
@end
NS_ASSUME_NONNULL_END
