//
//  NSObject+AL_ActiveRecord.h
//  patchwork
//
//  Created by Alex Lee on 27/06/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALUtilitiesHeader.h"

#ifdef __cplusplus
#import "ALDBColumnDefine.h"
#import "ALDBTypeDefs.h"
#import "ALDBColumnProperty.h"
#import "ALSQLClause.h"
#import "ALSQLValue.h"
#endif

NS_ASSUME_NONNULL_BEGIN

#define AS_COL(cls, propertyName)   [cls al_columnPropertiesForProperty:al_keypathForClass(cls, propertyName)]

typedef NSInteger ALDBRowIdType;

@protocol ALActiveRecord;
@interface NSObject (AL_ActiveRecord)

@property(PROP_ATOMIC_DEF, setter=al_setRowid:) ALDBRowIdType al_rowid;

#pragma mark - cpp methods
#ifdef __cplusplus

+ (const ALDBColumnProperty &)al_rowidColumn;
// not include rowid
+ (const std::list<const ALDBColumnProperty> &)al_allColumnProperties;
+ (const ALDBColumnProperty)al_columnPropertiesForProperty:(NSString *)propertyName;

+ (nullable NSArray<id<ALActiveRecord>> *)al_modelsWithCondition:(const ALDBCondition &)condition;
+ (nullable NSEnumerator<id<ALActiveRecord>> *)al_modelEnumeratorWithCondition:(const ALDBCondition &)condition;
#endif

#pragma mark - objc methods
+ (nullable NSString *)al_columnNameForPropertyNamed:(NSString *)propertyName;
+ (nullable id<ALActiveRecord>)al_modelWithRowId:(ALDBRowIdType)rowId;

//+ ()

- (BOOL)al_saveOrReplace:(BOOL)replaceOnConflict;
- (BOOL)al_updateOrReplace:(BOOL)replaceOnConflict;
- (BOOL)al_updateProperties:(NSArray<NSString *> *)propertiesNames replace:(BOOL)replaceOnConflict;

- (BOOL)al_deleteModel;

+ (BOOL)al_saveModels:(NSArray<id<ALActiveRecord>> *)models replace:(BOOL)replaceOnConflict;
+ (BOOL)al_updateProperties:(NSDictionary<NSString * /* propertyName */, id> *)propertyValues
              withCondition:(const ALDBCondition &)condition
                    replace:(BOOL)replaceOnCoflict;
+ (BOOL)al_updateModels:(NSArray<id<ALActiveRecord>> *)models replace:(BOOL)replaceOnConflict;

+ (BOOL)al_deleteModelsWithCondition:(const ALDBCondition &)condition;
@end

NS_ASSUME_NONNULL_END
