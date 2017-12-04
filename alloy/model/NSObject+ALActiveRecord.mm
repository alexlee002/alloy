//
//  NSObject+ALDatabase.m
//  alloy
//
//  Created by Alex Lee on 09/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "NSObject+ALActiveRecord.h"
#import "ALActiveRecord.h"
#import "ALLock.h"
#import "NSString+ALHelper.h"
#import "ALLogger.h"
#import "ALDBExpr.h"
#import "ALModelSelect.h"
#import "ALModelUpdate.h"
#import "ALModelDelete.h"
#import "ALModelInsert.h"
#import "ALDBResultColumn.h"
#import "ALDBTypeDefines.h"
#import "_ALModelHelper+cxx.h"
#import "NSObject+SQLValue.h"
#import "ALDBHandle+orm.h"


@implementation NSObject (ALDatabase)

+ (BOOL)al_inTransaction:(void (^)(BOOL *rollback))transaction {
    if (transaction) {
        return [[self al_database] al_inTransaction:transaction];
    }
    return NO;
}

- (BOOL)al_inTransaction:(void (^)(BOOL *rollback))transaction {
    return [self.class al_inTransaction:transaction];
}

#pragma mark -
+ (nullable NSArray/* <id<ALActiveRecord>> */ *)al_modelsInCondition:(const ALDBCondition &)condition {
    return [[[ALModelSelect selectModel:self properties:[self al_allColumnProperties]] where:condition] allObjects];
}

+ (nullable NSEnumerator/* <id<ALActiveRecord>> */ *)al_modelEnumeratorInCondition:(const ALDBCondition &)condition {
    return [[[ALModelSelect selectModel:self properties:[self al_allColumnProperties]] where:condition] objectEnumerator];
}

+ (nullable id<ALActiveRecord>)al_modelWithRowId:(ALDBRowIdType)rowId {
    NSEnumerator *enumerator = [self al_modelEnumeratorInCondition:ALDB_PROP(NSObject, al_rowid) == rowId];
    return [enumerator nextObject];
}

+ (NSInteger)al_modelsCountInCondition:(const ALDBCondition &)condition {
    ALDBResultSet *rs = [[[[ALModelSelect selectModel:self properties:ALDBProperty(aldb::Column::ANY).count()]
        where:condition] preparedStatement] query];
    if ([rs next]) {
        return [rs integerForColumnIndex:0];
    }
    return 0;
}

+ (nullable ALModelSelect *)al_modelFetcher {
    return [ALModelSelect selectModel:self properties:[self al_allColumnProperties]];
}

#pragma mark -
- (BOOL)al_saveOrReplace:(BOOL)replaceOnConflict {
    return [[ALModelInsert insertModel:self.class
                            properties:[self.class al_allColumnProperties]
                            onConflict:replaceOnConflict ? ALDBConflictPolicyReplace : ALDBConflictPolicyDefault]
        executeWithObjects:@[ self ]];
}

+ (BOOL)al_saveModels:(NSArray<id<ALActiveRecord>> *)models replace:(BOOL)replaceOnConflict {
    return [[ALModelInsert insertModel:self
                            properties:[self al_allColumnProperties]
                            onConflict:replaceOnConflict ? ALDBConflictPolicyReplace : ALDBConflictPolicyDefault]
            executeWithObjects: models];
}

#pragma mark -

- (BOOL)al_updateOrReplace:(BOOL)replaceOnConflict {
    std::shared_ptr<const ALDBCondition> conditionPtr = _ALDefaultModelUpdateCondition(self);
    if (!conditionPtr) {
        return NO;
    }
    
    return [[[ALModelUpdate updateModel:self.class
                             properties:[self.class al_allColumnProperties]
                             onConflict:replaceOnConflict ? ALDBConflictPolicyReplace : ALDBConflictPolicyDefault]
        where:*conditionPtr] executeWithObject:self];
}

- (BOOL)al_updateProperties:(NSArray<NSString *> *)propertiesNames replace:(BOOL)replaceOnConflict {
    std::shared_ptr<const ALDBCondition> conditionPtr = _ALDefaultModelUpdateCondition(self);
    if (!conditionPtr) {
        return NO;
    }
    
    ALDBPropertyList list;
    for (NSString *pn in propertiesNames) {
        list.push_back([self.class al_columnPropertyWithProperty:pn]);
    }
    return [[[ALModelUpdate updateModel:self.class
                             properties:list
                             onConflict:replaceOnConflict ? ALDBConflictPolicyReplace : ALDBConflictPolicyDefault]
             where:*conditionPtr] executeWithObject:self];
}

+ (BOOL)al_updateProperties:(NSDictionary<NSString * /* propertyName */, id> *)propertyValues
              withCondition:(const ALDBCondition &)condition
                    replace:(BOOL)replaceOnConflict {
    return [[self al_database]
        updateModelsWithClass:self
                       values:propertyValues
                   onConflict:replaceOnConflict ? ALDBConflictPolicyReplace : ALDBConflictPolicyDefault
                        where:condition];
}

+ (BOOL)al_updateModels:(NSArray<id<ALActiveRecord>> *)models replace:(BOOL)replaceOnConflict {
    return [[self al_database] updateModels:models
                                 onConflict:replaceOnConflict ? ALDBConflictPolicyReplace : ALDBConflictPolicyDefault];
}

#pragma mark -
- (BOOL)al_deleteModel {
    std::shared_ptr<const ALDBCondition> conditionPtr = _ALDefaultModelUpdateCondition(self);
    if (!conditionPtr) {
        return NO;
    }
    return [self.class al_deleteModelsWithCondition:*conditionPtr];
}

+ (BOOL)al_deleteModelsWithCondition:(const ALDBCondition &)condition {
    return [[[[ALModelDelete deleteModel:self] where:condition] preparedStatement] exec];
}

@end


