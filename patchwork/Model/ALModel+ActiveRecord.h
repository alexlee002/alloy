//
//  ALModel+ActiveRecord.h
//  patchwork
//
//  Created by Alex Lee on 2/25/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALModel_Define.h"
#import "ALDatabase.h"
#import "ActiveRecordAdditions.h"
#import "ALSQLSelectStatement.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kRowIdColumnName;

@interface ALSQLSelectStatement (ActiveRecord)

@property(readonly) NSArray<__kindof ALModel *> *_Nullable (^FETCH_MODELS)(void);
@property(readonly) ALSQLSelectStatement        *_Nonnull  (^APPLY_MODEL) (__unsafe_unretained Class _Nullable modelClass);

@end


// convert a model's prpoerty name to table column name
#ifndef AS_COL
#define AS_COL(class_type, property) [class_type mappedColumnNameForProperty:keypathForClass(class_type, property)]
#endif

#ifndef AS_COL_OJB
#define AS_COL_OBJ(obj, property) ((void)(NO && ((void)obj.property, NO)), [[obj class] mappedColumnNameForProperty:@#property])
#endif

// make a property as alias of 'rowid' property.
// IMPORTANT:   The ailas property must be type of NSInteger, otherwise, an assert would be rise.
//              Remember to implements your own "+primaryKeys" method and set the alias property as primaryKey.
//              The value of primry key would be ignored in "INSERT" operation,
//              and would be set as the database's last-insert-rowid value.
//
// @see: http://www.sqlite.org/lang_createtable.html ; session: "ROWIDs and the INTEGER PRIMARY KEY"
#define SYNTHESIZE_ROWID_ALIAS(alias_name)      \
+ (BOOL)hasRowidAlias { return YES; }           \
+ (nullable NSString *)rowidAliasPropertyName { \
    return @#alias_name;                        \
}                                               \
- (void)setRowid:(NSInteger)rowid {             \
    self.alias_name = rowid;                    \
}                                               \
- (NSInteger)rowid {                            \
    return self.alias_name;                     \
}                                               \
+ (NSArray<NSString *> *)primaryKeys {          \
    return @[ @#alias_name ];                   \
}

@class ALDBColumnInfo;
@class YYClassPropertyInfo;

#pragma mark - active record
@interface ALModel (ActiveRecord)

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
@property(PROP_ATOMIC_DEF) NSInteger rowid;
- (BOOL)isModelFromDB;

//???: should be deprecated?
+ (ALSQLSelectStatement *)fetcher;
+ (ALSQLUpdateStatement *)updateExector;

+ (NSDictionary<NSString *, ALDBColumnInfo *> *)columns;
+ (NSString *)mappedColumnNameForProperty:(NSString *)propertyName;


+ (void)inTransaction:(void(^)(ALDatabase *bindingDB, BOOL *rollback))transaction;
+ (void)inDeferredTransaction:(void(^)(ALDatabase *bindingDB, BOOL *rollback))transaction;
+ (void)inDatabase:(void(^)(ALDatabase *bindingDB))task;
- (void)inTransaction:(void(^)(ALDatabase *bindingDB, BOOL *rollback))transaction;
- (void)inDeferredTransaction:(void(^)(ALDatabase *bindingDB, BOOL *rollback))transaction;
- (void)inDatabase:(void(^)(ALDatabase *bindingDB))task;

+ (nullable NSArray<__kindof ALModel *> *)modelsWithCondition:(nullable ALSQLClause *)conditions;
// if '+withoutRowId' is YES, this method may not work.
+ (nullable __kindof ALModel *)modelWithId:(NSInteger)rowid;
- (BOOL)reload; // reload model from database

// return: the last insert row id
- (NSInteger)saveOrReplce:(BOOL)replaceExisted;
//???: merge with '-saveOrReplce:' ?
- (BOOL)updateOrReplace:(BOOL)replaceExisted;
- (BOOL)updateProperties:(nullable NSArray<NSString *> *)properties repleace:(BOOL)replaceExisted;

- (BOOL)deleteRecord;

// all models should be same class type.
+ (BOOL)saveRecords:(NSArray<ALModel *> *)models repleace:(BOOL)replaceExisted;
+ (BOOL)updateProperties:(NSDictionary *)contentValues
           withCondition:(nullable ALSQLClause *)conditions
                repleace:(BOOL)replaceExisted;
//???: merge with '+saveRecords:repleace:' ?
+ (BOOL)updateRecords:(NSArray<ALModel *> *)models replace:(BOOL)replaceExisted;
+ (BOOL)deleteRecordsWithCondition:(nullable ALSQLClause *)condition;

@end


#pragma mark - table mappings (override by subclasses)
@interface ALModel (ActiveRecord_Protected)

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
+ (nullable NSArray<NSString *> *)recordPropertyBlacklist;

/**
 *  Only properties in whitelist would be mapped to the database table column.
 *  The Order of table columns is the same as the order of whitelist.
 *
 *  return nil to ignore this feature.
 *
 *  @return an Array of property name, or nil;
 */
+ (nullable NSArray<NSString *> *)recordPropertyWhitelist;

// @{propertyName: columnName}
+ (nullable NSDictionary<NSString *, NSString *>  *)modelCustomColumnNameMapper;

/**
 *  The comparator to sort the table columns
 *  The default order is:
 *      if "-recordPropertyWhitelist" is not nil, using the same order of properties in whitelist.
 *      else the order should be: "primary key columns; unique columns; index columns; other columns"
 *
 *  @return typedef NSComparisonResult (^NSComparator)(ALDBColumnInfo *_Nonnull col1, ALDBColumnInfo *_Nonnull col2)
 */
+ (NSComparator)columnOrderComparator;

+ (void)customColumnDefine:(ALDBColumnInfo *)cloumn forProperty:(in YYClassPropertyInfo *)property;

/**
 *  Custom transform property value to save to database
 *
 *  @return value to save to database
 */
//- (id)customColumnValueTransformFrom{PropertyName};

/**
 *  Custom transform property value from resultSet
 *  @see "+modelsWithCondition:"
 */
//- (void)customTransform{PropertyName}FromRecord:(in FMResultSet *)rs columnIndex:(int)index;

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

NS_ASSUME_NONNULL_END
