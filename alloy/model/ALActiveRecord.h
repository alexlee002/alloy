//
//  ALActiveRecord.h
//  patchwork
//
//  Created by Alex Lee on 27/06/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ALDBColumnDefine.h"

@class YYClassPropertyInfo;
@protocol ALActiveRecord <NSObject>

@optional

/**
 * If YES, the table binging to this model would automatical create and migrate changes of model to database.
 * If NO, you should create / alter table yourself in the callback of the database opened.
 */
+ (BOOL)autoBindDatabase;

/**
 * @return The name of database table that associates with this model.
 * Normally, the model name should be a noun of English. so the default value return would be the pluralize of model name.
 * a) If the model name ends with "Model", the subfix "Model" will be removed in the table name.
 * b) If the model name is not ends with English letter, the subfix "_list" will be added to table name.
 * c) If the model name is CamelCase style, the table name will be converted to lowercase words and joined with "_".
 *
 * eg: "UserModel" => "users", "fileMeta" => "file_metas".
 */
+ (nullable NSString *)tableName;

/**
 *  @return The database identifier (normally the database file path) that associates with this model.
 *  Return nil if the model doesn't bind to any database.
 */
+ (nullable NSString *)databaseIdentifier;

/**
 *  All properties in blacklist would not be mapped to the database table column.
 *  return nil to ignore this feature.
 *
 *  @return an Array of property name, or nil;
 */
+ (nullable NSArray<NSString *> *)columnPropertyBlacklist;

/**
 *  Only properties in whitelist would be mapped to the database table column.
 *  The Order of table columns is the same as the order of whitelist.
 *
 *  return nil to ignore this feature.
 *
 *  @return an Array of property name, or nil;
 */
+ (nullable NSArray<NSString *> *)columnPropertyWhitelist;

// @{propertyName: columnName}
+ (nullable NSDictionary<NSString *, NSString *>  *)modelCustomColumnNameMapper;

/**
 *  The comparator to sort the table columns
 *  The default order is:
 *      if "-columnPropertyWhitelist" is not nil, using the same order of properties in whitelist.
 *      else the order should be: "primary key columns; unique columns; index columns; other columns"
 *
 *  @return typedef NSComparisonResult (^NSComparator)(ALDBColumnInfo *_Nonnull col1, ALDBColumnInfo *_Nonnull col2)
 */
+ (NSComparator _Nullable )columnOrderComparator;

+ (void)customDefineColumn:(ALDBColumnDefine &)cloumn forProperty:(in YYClassPropertyInfo *_Nonnull)property;

/**
 * Custom defines the column type for property
 *
 */
//+ (ALDBColumnType)customColumnTypeFor{PropertyName};
 
/**
 *  Custom transform property value to save to database
 *
 *  @return value to save to database
 */
//- (id)customGetColumnValueFor{PropertyName};

/**
 *  Custom transform property value from resultSet
 *  @see "+modelsWithCondition:"
 */
//- (void)customSet{PropertyName}WithColumnValue:(id)value;

/**
 * key: the property name
 * specified the model's primary key, if it's not set and '+withoudRowId' returns NO,  'rowid' is set as default.
 * If the model cantains only one primary key, and the primary key is type of "NSInteger", please use 'rowid' property directly.
 *
 * @see http://www.sqlite.org/rowidtable.html
 * @see http://www.sqlite.org/withoutrowid.html
 * @see "rowid" property
 */
+ (nullable NSArray<NSString *>            *)primaryKeys;
+ (nullable NSArray<NSArray<NSString *> *> *)uniqueKeys;
+ (nullable NSArray<NSArray<NSString *> *> *)indexKeys;

// default is NO, if return YES, prmaryKeys must be set.
+ (BOOL)withoutRowId;
@end
