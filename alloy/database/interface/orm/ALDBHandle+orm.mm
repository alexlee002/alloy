//
//  ALDBHandle+orm.m
//  alloy
//
//  Created by Alex Lee on 01/11/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDBHandle+orm.h"
#import "NSObject+ALDBBindings.h"
#import "ALDBExpr.h"
#import "NSObject+ALDBBindings.h"
#import "NSObject+SQLValue.h"
#import "sql_update.hpp"
#import "qualified_table_name.hpp"
#import "ALLogger.h"
#import "_ALModelHelper+cxx.h"
#import "ALModelInsert.h"
#import "ALModelUpdate.h"
#import "ALModelDelete.h"

@implementation ALDBHandle (orm)

#pragma mark - select
- (nullable ALModelSelect *)preparedQueryForModelClass:(Class)modelClass {
    return [[ALModelSelect alloc] initWithDatabase:self
                                             table:ALTableNameForModel(modelClass)
                                        modelClass:modelClass
                                        properties:[modelClass al_allColumnProperties]];
}

- (nullable ALModelSelect *)preparedQueryForModelClass:(Class)modelClass
                                            properties:(const ALDBResultColumnList &)results {
    return [[ALModelSelect alloc] initWithDatabase:self
                                             table:ALTableNameForModel(modelClass)
                                        modelClass:modelClass
                                        properties:results];
}

- (nullable ALModelSelect *)preparedQueryForModelClass:(Class)modelClass
                                               inTable:(NSString *)tableName
                                            properties:(const ALDBResultColumnList &)results {
    return [[ALModelSelect alloc] initWithDatabase:self
                                             table:ALTableNameForModel(modelClass)
                                        modelClass:modelClass
                                        properties:results];
}

#pragma mark - insert

- (BOOL)insertModel:(NSObject *)model onConflict:(ALDBConflictPolicy)policy {
    if (model == nil) {
        return NO;
    }
    return [[[ALModelInsert alloc] initWithDatabase:self
                                              table:ALTableNameForModel(model.class)
                                         modelClass:model.class
                                         properties:[model.class al_allColumnProperties]
                                         onConflict:policy]
            executeWithObjects:@[ model ]];
}

- (BOOL)insertModels:(NSArray<NSObject *> *)models onConflict:(ALDBConflictPolicy)policy {
    if (models.count == 0) {
        return NO;
    }
    Class modelClass = models.firstObject.class;
    return [[[ALModelInsert alloc] initWithDatabase:self
                                              table:ALTableNameForModel(modelClass)
                                         modelClass:modelClass
                                         properties:[modelClass al_allColumnProperties]
                                         onConflict:policy]
            executeWithObjects:models];
}

- (BOOL)insertProperties:(const ALDBPropertyList &)propertyList
                ofModels:(NSArray<NSObject *> *)models
              onConflict:(ALDBConflictPolicy)policy {
    if (models.count == 0) {
        return NO;
    }
    Class modelClass = models.firstObject.class;
    return [[[ALModelInsert alloc] initWithDatabase:self
                                              table:ALTableNameForModel(modelClass)
                                         modelClass:modelClass
                                         properties:propertyList
                                         onConflict:policy]
            executeWithObjects:models];
}

- (BOOL)insertProperties:(const ALDBPropertyList &)propertyList
                ofModels:(NSArray<NSObject *> *)models
               intoTable:(NSString *)table
              onConflict:(ALDBConflictPolicy)policy {
    if (models.count == 0) {
        return NO;
    }
    Class modelClass = models.firstObject.class;
    return [[[ALModelInsert alloc] initWithDatabase:self
                                              table:table
                                         modelClass:modelClass
                                         properties:propertyList
                                         onConflict:policy]
            executeWithObjects:models];
}

#pragma mark - update

- (BOOL)updateModel:(NSObject *)model onConflict:(ALDBConflictPolicy)policy {
    return [self updateProperties:[model.class al_allColumnProperties] ofModel:model onConflict:policy];
}

- (BOOL)updateModels:(NSArray<NSObject *> *)models onConflict:(ALDBConflictPolicy)policy {
    return [self updateProperties:[models.firstObject.class al_allColumnProperties] ofModels:models onConflict:policy];
}

- (BOOL)updateProperties:(const ALDBPropertyList &)propertyList
                ofModels:(NSArray<NSObject *> *)models
              onConflict:(ALDBConflictPolicy)policy {
    if (models.count == 0) {
        return NO;
    }
    
    Class modelClass = models.firstObject.class;
    NSError *error = nil;
    BOOL ret = [self inTransaction:^(BOOL * _Nonnull rollback) {
        ALDBStatement *stmt = nil;
        for (id model in models) {
            if ([model class] != modelClass) {
                ALAssert(NO, @"model class (\"%@\") is not expected (\"%@\")!", [model class], modelClass);
                continue;
            }
            
            std::shared_ptr<const ALDBCondition> conditionPtr = _ALDefaultModelUpdateCondition(model);
            if (!conditionPtr) {
                return;
            }
            
            ALDBCondition condition = *conditionPtr;
            if (stmt == nil) {
                stmt = [[[[ALModelUpdate alloc] initWithDatabase:self
                                                           table:ALTableNameForModel(modelClass)
                                                      modelClass:modelClass
                                                      properties:propertyList
                                                      onConflict:policy] where:condition] preparedStatement];
                if (stmt == nil) {
                    return;
                }
            }
            
            std::list<const aldb::SQLValue> values;
            for (auto p : propertyList) {
                ALDBColumnBinding *binding = p.columnBinding();
                id val = _ALColumnValueForModelProperty(model, binding);
                values.push_back([val al_SQLValue]);
            }
            values.insert(values.end(), condition.values().begin(), condition.values().end());
            if (![stmt exec:values]) {
                //TODO: exit?
            }
        }
        
    } error:&error];
    
    if (!ret && error) {
        ALLogError(@"%@", error);
    }
    return ret;
}

- (BOOL)updateProperties:(const ALDBPropertyList &)propertyList
                 ofModel:(NSObject *)model
              onConflict:(ALDBConflictPolicy)policy {
    if (model == nil) {
        return NO;
    }
    
    std::shared_ptr<const ALDBCondition> conditionPtr = _ALDefaultModelUpdateCondition(model);
    if (!conditionPtr) {
        return NO;
    }

    return [[[[ALModelUpdate alloc] initWithDatabase:self
                                               table:ALTableNameForModel(model.class)
                                          modelClass:model.class
                                          properties:propertyList
                                          onConflict:policy] where:*conditionPtr]
            executeWithObject:model];
}

- (BOOL)updateProperties:(const ALDBPropertyList &)propertyList
                ofModels:(NSArray<NSObject *> *)objs
                 inTable:(NSString *)table
              onConflict:(ALDBConflictPolicy)policy
      identifyProperties:(const ALDBPropertyList &)identifiedProperties {
    if (objs.count == 0) {
        return NO;
    }

    ALDBCondition where;
    for (auto p : identifiedProperties) {
        where = where && (p == ALDBExpr::BIND_PARAM);
    }

    NSError *error = nil;
    BOOL ret = [self inTransaction:^(BOOL *_Nonnull rollback) {
        ALDBStatement *stmt = nil;
        for (id model in objs) {
            if (stmt == nil) {
                stmt = [[[[ALModelUpdate alloc] initWithDatabase:self
                                                           table:table
                                                      modelClass:objs.firstObject.class
                                                      properties:propertyList
                                                      onConflict:policy] where:where] preparedStatement];
                if (stmt == nil) {
                    return;
                }
            }
            std::list<const aldb::SQLValue> values;
            ALDBPropertyList allParams(propertyList);
            allParams.insert(allParams.end(), identifiedProperties.begin(), identifiedProperties.end());
            for (auto p : allParams) {
                ALDBColumnBinding *binding = p.columnBinding();
                id val = _ALColumnValueForModelProperty(model, binding);
                values.push_back([val al_SQLValue]);
            }
            if (![stmt exec:values]) {
                // TODO: exit?
            }
        }
    } error:&error];

    if (!ret && error) {
        ALLogError(@"%@", error);
    }
    return ret;
}

- (BOOL)updateModelsWithClass:(Class)modelClass
                       values:(NSDictionary<NSString *, id> *)values
                   onConflict:(ALDBConflictPolicy)policy
                        where:(const ALDBCondition &)where {
    
    return [self updateModelsWithClass:modelClass
                               inTable:ALTableNameForModel(modelClass)
                                values:values
                            onConflict:policy
                                 where:where];
}

- (BOOL)updateModelsWithClass:(Class)modelClass
                      inTable:(NSString *)table
                       values:(NSDictionary<NSString *, id> *)values
                   onConflict:(ALDBConflictPolicy)policy
                        where:(const ALDBCondition &)where {
    std::list<const std::pair<const aldb::UpdateColumns, const ALDBExpr>> setList;
    for (NSString *pn in values.allKeys) {
        setList.push_back({[modelClass al_columnPropertyWithProperty:pn], ALDBExpr(values[pn])});
    }
    
    aldb::SQLUpdate update;
    update.update(table.UTF8String, (aldb::ConflictPolicy) policy).set(setList).where(where);
    
    NSError *error = nil;
    BOOL ret = [self exec:update error:&error];
    if (!ret && error) {
        ALLogError(@"%@", error);
    }
    return ret;
}

- (BOOL)updateModelsWithClass:(Class)modelClass
                      inTable:(NSString *)table
                       values:(NSDictionary<NSString *, id> *)values
                   onConflict:(ALDBConflictPolicy)policy
                        where:(const ALDBCondition &)where
                      orderBy:(const std::list<const aldb::OrderClause> &)orderBy
                        limit:(const ALDBExpr &)limit
                       offset:(const ALDBExpr &)offset {
    std::list<const std::pair<const aldb::UpdateColumns, const ALDBExpr>> setList;
    for (NSString *pn in values.allKeys) {
        setList.push_back({[modelClass al_columnPropertyWithProperty:pn], ALDBExpr(values[pn])});
    }

    aldb::SQLUpdate update;
    update.update(table.UTF8String, (aldb::ConflictPolicy) policy)
        .set(setList)
        .where(where)
        .order_by(orderBy)
        .limit(limit)
        .offset(offset);

    NSError *error = nil;
    BOOL ret = [self exec:update error:&error];
    if (!ret && error) {
        ALLogError(@"%@", error);
    }
    return ret;
}

#pragma mark - delete
- (BOOL)deleteModel:(NSObject *)obj {
    if (obj == nil) {
        return NO;
    }

    std::shared_ptr<const ALDBCondition> conditionPtr = _ALDefaultModelUpdateCondition(obj);
    if (!conditionPtr) {
        return NO;
    }

    return [[[[ALModelDelete alloc] initWithDatabase:self table:ALTableNameForModel(obj.class) modelClass:obj.class]
        where:*conditionPtr] executeWithObject:obj];
}

- (BOOL)deleteModelsWithClass:(Class)modelClass where:(const ALDBCondition &)where {
    return [[[[[ALModelDelete alloc] initWithDatabase:self table:ALTableNameForModel(modelClass) modelClass:modelClass]
        where:where] preparedStatement] exec];
}

- (BOOL)deleteModelsWithClass:(Class)modelClass
                      inTable:(NSString *)table
                        where:(const ALDBCondition &)where
                      orderBy:(const std::list<const aldb::OrderClause> &)orderBy
                        limit:(const ALDBExpr &)limit
                       offset:(const ALDBExpr &)offset {
    return
        [[[[[[[[ALModelDelete alloc] initWithDatabase:self table:ALTableNameForModel(modelClass) modelClass:modelClass]
            where:where] orderBy:orderBy] limit:limit] offset:offset] preparedStatement] exec];
}

@end
