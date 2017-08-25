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
#endif

NS_ASSUME_NONNULL_BEGIN

typedef NSInteger ALDBRowIdType;

@protocol ALActiveRecord;
@interface NSObject (AL_ActiveRecord)

@property(PROP_ATOMIC_DEF) ALDBRowIdType al_rowid;

#pragma mark - cpp methods
#ifdef __cplusplus
//{propertyName: ColumnDefine}
+ (const std::unordered_map<std::string, std::shared_ptr<ALDBColumnDefine>>)al_modelPropertyColumnsMap;

+ (nullable NSArray<id<ALActiveRecord>> *)al_modelsWithCondition:(const ALDBCondition &)condition;
+ (nullable NSEnumerator<id<ALActiveRecord>> *)al_modelEnumeratorWithCondition:(const ALDBCondition &)condition;
#endif

#pragma mark - objc methods
+ (nullable NSString *)al_columnNameForPropertyNamed:(NSString *)propertyName;
+ (nullable id<ALActiveRecord>)al_modelWithRowId:(ALDBRowIdType)rowId;

- (BOOL)saveOrReplace:(BOOL)replaceOnConflict;
- (BOOL)updateOrReplace:(BOOL)replaceOnConflict;
- (BOOL)updateProperties:(NSArray<NSString *> *)propertiesNames replace:(BOOL)replaceOnConflict;

- (BOOL)deleteModel;

+ (BOOL)saveModels:(NSArray<id<ALActiveRecord>> *)models replace:(BOOL)replaceOnConflict;
+ (BOOL)updateProperties:(NSDictionary<NSString *, id> *)contentValues withCodition:(const ALDBCondition &)condition replace:(BOOL)replaceOnCoflict;
+ (BOOL)updateModels:(NSArray<id<ALActiveRecord>> *)models replace:(BOOL)replaceOnConflict;

+ (BOOL)deleteModelsWithCondition:(const ALDBCondition &)condition;
@end

NS_ASSUME_NONNULL_END
