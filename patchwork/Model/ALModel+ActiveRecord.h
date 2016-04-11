//
//  ALModel+ActiveRecord.h
//  patchwork
//
//  Created by Alex Lee on 2/25/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALModel_Define.h"
#import "ALSQLCondition.h"
#import "ALDatabase.h"

NS_ASSUME_NONNULL_BEGIN

#define AS_COL(class_type, property) [class_type mappedColumnNameForProperty:keypathForClass(class_type, property)]
#define AS_COL_O(obj, property)      ((void)(NO && ((void)obj.property, NO)),\
                                         [[obj class] mappedColumnNameForProperty:@#property])


extern NSString * const kRowIdColumnName;

@interface ALSQLSelectCommand (ActiveRecord)

@property(readonly) NSArray<__kindof ALModel *> *_Nullable (^FETCH_MODELS)(void);
@property(readonly) ALSQLSelectCommand *_Nonnull           (^APPLY_MODEL) (Class _Nonnull modelClass);

- (void)fetchWithCompletion:(void (^_Nullable)(FMResultSet *_Nullable rs))completion;

@end



@class ALDBColumnInfo;
@class YYClassPropertyInfo;

#pragma mark - active record
@interface ALModel (ActiveRecord)

@property(PROP_ATOMIC_DEF) NSInteger rowid; // the rowid in database, if the table is "without rowid", return 0;

//+ (nullable ALDatabase *)DB;
+ (NSDictionary<NSString *, ALDBColumnInfo *> *)columns;
+ (NSString *)mappedColumnNameForProperty:(NSString *)propertyName;
+ (nullable NSArray<__kindof ALModel *> *)modelsWithCondition:(nullable ALSQLCondition *)condition;
+ (ALSQLSelectCommand *)fetcher;
+ (ALSQLUpdateCommand *)updateExector;

- (BOOL)saveOrReplce:(BOOL)replaceExisted;
- (BOOL)updateOrReplace:(BOOL)replaceExisted;
- (BOOL)updateProperties:(nullable NSArray<NSString *> *)properties repleace:(BOOL)replaceExisted;

- (BOOL)deleteRecord;

+ (BOOL)saveRecords:(NSArray<ALModel *> *)models repleace:(BOOL)replaceExisted;
+ (BOOL)updateProperties:(NSDictionary *)contentValues
           withCondition:(nullable ALSQLCondition *)condition
                repleace:(BOOL)replaceExisted;
+ (BOOL)updateRecords:(NSArray<ALModel *> *)models replace:(BOOL)replaceExisted;
+ (BOOL)deleteRecordsWithCondition:(nullable ALSQLCondition *)condition;

// sql statments
+ (NSString *)tableSchema;
+ (NSArray<NSString *> *)indexStatements;

@end


#pragma mark - table mappings (override by subclasses)
@interface ALModel (ActiveRecord_Protected)

+ (nullable NSString *)tableName;
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

// key: the property name
// specified the model's primary key, if it's not set, "_id" is set as default.
+ (nullable NSArray<NSString *>            *)primaryKeys;
+ (nullable NSArray<NSArray<NSString *> *> *)uniqueKeys;
+ (nullable NSArray<NSArray<NSString *> *> *)indexKeys;

// default is NO, if return YES, prmaryKeys must be set.
+ (BOOL)withoudRowId;

@end

NS_ASSUME_NONNULL_END
