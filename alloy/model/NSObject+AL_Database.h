//
//  NSObject+AL_Database.h
//  alloy
//
//  Created by Alex Lee on 09/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALMacros.h"
#import "ALActiveRecord.h"
#import "ALDBTableBinding.h"
#import "ALDBProperty.h"
#import "ALModelSelect.h"
#import "ALDatabase.h"

typedef NSInteger ALDBRowIdType;

// get ALDBColumnProperty binding with specified property
#define ALDB_PROP(cls, propertyName)   [cls al_columnPropertyWithProperty:al_keypathForClass(cls, propertyName)]

// get columnName binding with specified property
#define ALDB_COL(cls, propertyName) [cls al_columnNameForProperty:al_keypathForClass(cls, propertyName)]

// make a property as alias of 'rowid' property.
// IMPORTANT:   The ailas property must be type of NSInteger, otherwise, an assert would be rise.
//              Remember to implements your own "+primaryKeys" method and set the alias property as primaryKey.
//              The value of primry key would be ignored in "INSERT" operation,
//              and would be set as the database's last-insert-rowid value.
//
// @see: http://www.sqlite.org/lang_createtable.html ; session: "ROWIDs and the INTEGER PRIMARY KEY"
#define AL_SYNTHESIZE_ROWID_ALIAS(alias_name)          \
    +(BOOL) al_hasRowidAlias {                         \
        return YES;                                    \
    }                                                  \
    +(nullable NSString *) al_rowidAliasPropertyName { \
        return @ #alias_name;                          \
    }                                                  \
    -(void) al_setRowid : (NSInteger) rowid {          \
        self.alias_name = rowid;                       \
    }                                                  \
    -(NSInteger) al_rowid {                            \
        return self.alias_name;                        \
    }                                                  \
    +(NSArray<NSString *> *) primaryKeys {             \
        return @[ @ #alias_name ];                     \
    }

#define AL_DISABLE_ROWID_ALIAS()                       \
    +(BOOL) al_hasRowidAlias {                         \
        return NO;                                     \
    }                                                  \
    +(nullable NSString *) al_rowidAliasPropertyName { \
        return nil;                                    \
    }

NS_ASSUME_NONNULL_BEGIN

OBJC_EXPORT NSString *ALTableNameForModel(__unsafe_unretained Class cls);

@class ALDatabase;
@interface NSObject (AL_Database)
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

+ (nullable ALDatabase *)al_database;
+ (nullable ALDBTableBinding *)al_tableBindings;
+ (const ALDBPropertyList)al_allColumnProperties;
+ (const ALDBProperty )al_columnPropertyWithProperty:(NSString *)propertyName;
+ (nullable NSString *)al_columnNameForProperty:(NSString *)propertyName;

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
