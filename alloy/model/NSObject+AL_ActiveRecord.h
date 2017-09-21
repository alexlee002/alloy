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
#import "ALARExecutor.h"
#endif


// get ALDBColumnProperty binding with specified property
#define ALDB_PROP(cls, propertyName)   [cls al_columnPropertyForProperty:al_keypathForClass(cls, propertyName)]

// get columnName binding with specified property
#define ALDB_COL(cls, propertyName) [cls al_columnNameForPropertyNamed:al_keypathForClass(cls, propertyName)]

// make a property as alias of 'rowid' property.
// IMPORTANT:   The ailas property must be type of NSInteger, otherwise, an assert would be rise.
//              Remember to implements your own "+primaryKeys" method and set the alias property as primaryKey.
//              The value of primry key would be ignored in "INSERT" operation,
//              and would be set as the database's last-insert-rowid value.
//
// @see: http://www.sqlite.org/lang_createtable.html ; session: "ROWIDs and the INTEGER PRIMARY KEY"
#define AL_SYNTHESIZE_ROWID_ALIAS(alias_name)       \
    +(BOOL) hasRowidAlias {                         \
        return YES;                                 \
    }                                               \
    +(nullable NSString *) rowidAliasPropertyName { \
        return @ #alias_name;                       \
    }                                               \
    -(void) al_setRowid : (NSInteger) rowid {       \
        self.alias_name = rowid;                    \
    }                                               \
    -(NSInteger) al_rowid {                         \
        return self.alias_name;                     \
    }                                               \
    +(NSArray<NSString *> *) primaryKeys {          \
        return @[ @ #alias_name ];                  \
    }

#define AL_DISABLE_ROWID_ALIAS()                    \
    +(BOOL) hasRowidAlias {                         \
        return NO;                                  \
    }                                               \
    +(nullable NSString *) rowidAliasPropertyName { \
        return nil;                                 \
    }


typedef NSInteger ALDBRowIdType;

NS_ASSUME_NONNULL_BEGIN

@protocol ALActiveRecord;
@interface NSObject (AL_ActiveRecord)

/**
 * @see http://www.sqlite.org/rowidtable.html
 * @see class method: "+primaryKeys"
 *
 * The rowid in database, if it is "without rowid" table, return 0;
 * @important  the rowid value would be modified if using "-[saveOrReplce:]" or
 *             "+[saveRecords:repleace:]" if the unique keys conflict.
 *             So, if tables associates with other table, eg, "belongs_to",
 *             "has_many", etc. you should carefully consider.
 */
@property(PROP_ATOMIC_DEF, setter=al_setRowid:) ALDBRowIdType al_rowid;
@property(PROP_ATOMIC_DEF, setter=al_setAutoIncrement:) BOOL  al_autoIncrement;

#pragma mark - cpp methods
#ifdef __cplusplus

//+ (const ALDBColumnProperty &)al_rowidColumn;
+ (const std::list<const ALDBColumnProperty> &)al_allColumnProperties;
+ (const ALDBColumnProperty)al_columnPropertyForProperty:(NSString *)propertyName;

+ (nullable NSArray/* <id<ALActiveRecord>> */ *)al_modelsWithCondition:(const ALDBCondition &)condition;
+ (nullable NSEnumerator/* <id<ALActiveRecord>> */ *)al_modelEnumeratorWithCondition:(const ALDBCondition &)condition;
+ (NSInteger)al_modelsCountWithCondition:(const ALDBCondition &)condition;
#endif

#pragma mark - objc methods
+ (nullable id<ALARFetcher>)al_modelFetcher;
//+ (nullable id<ALARExecutor>)al_modelExecutor;

+ (void)al_inTransaction:(void (^)(BOOL *rollback))transaction;
- (void)al_inTransaction:(void (^)(BOOL *rollback))transaction;

+ (nullable NSString *)al_columnNameForPropertyNamed:(NSString *)propertyName;
+ (nullable id<ALActiveRecord>)al_modelWithRowId:(ALDBRowIdType)rowId;

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
