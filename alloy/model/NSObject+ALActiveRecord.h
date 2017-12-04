//
//  NSObject+ALDatabase.h
//  alloy
//
//  Created by Alex Lee on 09/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALMacros.h"
#import "ALActiveRecord.h"
#import "ALModelSelect.h"
#import "NSObject+ALDBBindings.h"

NS_ASSUME_NONNULL_BEGIN
@interface NSObject (ALDatabase)

+ (BOOL)al_inTransaction:(void (^)(BOOL *rollback))transaction;
- (BOOL)al_inTransaction:(void (^)(BOOL *rollback))transaction;

#pragma mark -
+ (nullable NSArray/* <id<ALActiveRecord>> */ *)al_modelsInCondition:(const ALDBCondition &)condition;
+ (nullable NSEnumerator/* <id<ALActiveRecord>> */ *)al_modelEnumeratorInCondition:(const ALDBCondition &)condition;
+ (nullable id<ALActiveRecord>)al_modelWithRowId:(ALDBRowIdType)rowId;
+ (NSInteger)al_modelsCountInCondition:(const ALDBCondition &)condition;

+ (nullable ALModelSelect *)al_modelFetcher;

#pragma mark -
- (BOOL)al_saveOrReplace:(BOOL)replaceOnConflict;
+ (BOOL)al_saveModels:(NSArray<id<ALActiveRecord>> *)models replace:(BOOL)replaceOnConflict;

#pragma mark -
- (BOOL)al_updateOrReplace:(BOOL)replaceOnConflict;
- (BOOL)al_updateProperties:(NSArray<NSString *> *)propertiesNames replace:(BOOL)replaceOnConflict;
+ (BOOL)al_updateProperties:(NSDictionary<NSString * /* propertyName */, id> *)propertyValues
              withCondition:(const ALDBCondition &)condition
                    replace:(BOOL)replaceOnCoflict;
+ (BOOL)al_updateModels:(NSArray<id<ALActiveRecord>> *)models replace:(BOOL)replaceOnConflict;

#pragma mark - 
- (BOOL)al_deleteModel;
+ (BOOL)al_deleteModelsWithCondition:(const ALDBCondition &)condition;

@end

NS_ASSUME_NONNULL_END

