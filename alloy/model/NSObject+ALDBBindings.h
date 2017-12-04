//
//  NSObject+ALDBBindings.h
//  alloy
//
//  Created by Alex Lee on 01/11/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALMacros.h"
#import "ALDatabase.h"
#import "ALDBTableBinding.h"
#import "ALDBProperty.h"

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

/**
 * @return The name of database table that associates with this model.
 * Normally, the model name should be a noun of English. so the default value return would be the pluralize of model name.
 * a) If the model name is not ends with English letter, the subfix "_list" will be added to table name.
 * b) If the model name is CamelCase style, the table name will be converted to lowercase words and joined with "_".
 *
 * eg: "UserModel" => "user_models", "fileMeta" => "file_metas".
 */
OBJC_EXPORT NSString *ALTableNameForModel(__unsafe_unretained Class cls);
@interface NSObject (ALDBBindings)
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

/**
 * Use in SQL INSERT operation.
 * If return YES, ignore the value of the model's primary key("rowid" or its alias),
 *      after the model is inserted, the value of the primary key would be set to the value of "last_insert_rowid".
 * If return NO, insert the specified value of the model's primary key into the database.
 */
@property(PROP_ATOMIC_DEF, setter=al_setAutoIncrement:) BOOL  al_autoIncrement;

/**
 * get the model's associated database. this is used in activerecord pattern.
 */
+ (nullable ALDatabase *)al_database;
+ (nullable ALDBTableBinding *)al_tableBindings;
+ (const ALDBPropertyList)al_allColumnProperties;
+ (const ALDBProperty )al_columnPropertyWithProperty:(NSString *)propertyName;
+ (nullable NSString *)al_columnNameForProperty:(NSString *)propertyName;
@end
NS_ASSUME_NONNULL_END
