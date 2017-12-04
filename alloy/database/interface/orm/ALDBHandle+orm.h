//
//  ALDBHandle+orm.h
//  alloy
//
//  Created by Alex Lee on 01/11/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDBHandle.h"
#import "ALModelSelect.h"

NS_ASSUME_NONNULL_BEGIN

@interface ALDBHandle (orm)

#pragma mark - select
- (nullable ALModelSelect *)preparedQueryForModelClass:(Class)modelClass;
- (nullable ALModelSelect *)preparedQueryForModelClass:(Class)modelClass
                                            properties:(const ALDBResultColumnList &)results;
- (nullable ALModelSelect *)preparedQueryForModelClass:(Class)modelClass
                                               inTable:(NSString *)tableName
                                            properties:(const ALDBResultColumnList &)results;

#pragma mark - insert

- (BOOL)insertModel:(NSObject *)model onConflict:(ALDBConflictPolicy)policy;
- (BOOL)insertModels:(NSArray<NSObject *> *)models onConflict:(ALDBConflictPolicy)policy;

- (BOOL)insertProperties:(const ALDBPropertyList &)propertyList
                ofModels:(NSArray<NSObject *> *)objs
              onConflict:(ALDBConflictPolicy)policy;

- (BOOL)insertProperties:(const ALDBPropertyList &)propertyList
                ofModels:(NSArray<NSObject *> *)objs
               intoTable:(NSString *)table
              onConflict:(ALDBConflictPolicy)policy;

#pragma mark - update

- (BOOL)updateModel:(NSObject *)model onConflict:(ALDBConflictPolicy)policy;
- (BOOL)updateProperties:(const ALDBPropertyList &)propertyList
                 ofModel:(NSObject *)model
              onConflict:(ALDBConflictPolicy)policy;

- (BOOL)updateModels:(NSArray<NSObject *> *)models onConflict:(ALDBConflictPolicy)policy;
- (BOOL)updateProperties:(const ALDBPropertyList &)propertyList
                ofModels:(NSArray<NSObject *> *)models
              onConflict:(ALDBConflictPolicy)policy;

- (BOOL)updateModelsWithClass:(Class)modelClass
                       values:(NSDictionary<NSString * /* propertyName */, id> *)values
                   onConflict:(ALDBConflictPolicy)policy
                        where:(const ALDBCondition &)where;


- (BOOL)updateProperties:(const ALDBPropertyList &)propertyList
                ofModels:(NSArray<NSObject *> *)objs
                 inTable:(NSString *)table
              onConflict:(ALDBConflictPolicy)policy
      identifyProperties:(const ALDBPropertyList &)identifiedProperties;

- (BOOL)updateModelsWithClass:(Class)modelClass
                      inTable:(NSString *)table
                       values:(NSDictionary<NSString * /* propertyName */, id> *)values
                   onConflict:(ALDBConflictPolicy)policy
                        where:(const ALDBCondition &)where;

- (BOOL)updateModelsWithClass:(Class)modelClass
                      inTable:(NSString *)table
                       values:(NSDictionary<NSString * /* propertyName */, id> *)values
                   onConflict:(ALDBConflictPolicy)policy
                        where:(const ALDBCondition &)where
                      orderBy:(const std::list<const aldb::OrderClause> &)orderBy
                        limit:(const ALDBExpr &)limit
                       offset:(const ALDBExpr &)offset;

#pragma mark - delete
- (BOOL)deleteModel:(NSObject *)objs;
- (BOOL)deleteModelsWithClass:(Class)modelClass where:(const ALDBCondition &)where;
- (BOOL)deleteModelsWithClass:(Class)modelClass
                      inTable:(NSString *)table
                        where:(const ALDBCondition &)where
                      orderBy:(const std::list<const aldb::OrderClause> &)orderBy
                        limit:(const ALDBExpr &)limit
                       offset:(const ALDBExpr &)offset;

@end

NS_ASSUME_NONNULL_END
