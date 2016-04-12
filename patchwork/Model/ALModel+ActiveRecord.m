//
//  ALModel+ActiveRecord.m
//  patchwork
//
//  Created by Alex Lee on 2/25/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALModel+ActiveRecord.h"
#import "UtilitiesHeader.h"
#import "YYModel.h"
#import "BlocksKitExtension.h"
#import "NSString+Helper.h"
#import "BlocksKit.h"
#import "ALDBColumnInfo.h"
#import "ALDatabase.h"
#import "FMDB.h"
#import "ALSQLDeleteCommand.h"
#import "ALSQLInsertCommand.h"
#import "ALSQLSelectCommand.h"
#import "ALSQLUpdateCommand.h"
#import "ALOCRuntime.h"
#import <sqlite3.h>
#import <objc/message.h>


NSString * const kRowIdColumnName = @"rowid";

@class _ColumnPropertyInfo;
static FORCE_INLINE NSString * suggestedSqliteDataType(YYClassPropertyInfo *property);
static FORCE_INLINE void setModelPropertyValueFromResultSet(FMResultSet *rs, int columnIndex, ALModel *model,
                                                            _ColumnPropertyInfo *propertyInfo);
static FORCE_INLINE void constructModelFromResultSet(FMResultSet *rs, ALModel *model,
                                                     NSDictionary<NSString *, id> *columnPropertyMapper);
static FORCE_INLINE NSArray<__kindof ALModel *> *_Nullable modelsFromResultSet(FMResultSet *rs, Class modelClass);


@implementation ALSQLSelectCommand (ActiveRecord)

static const void * const kModelClassAssociatedKey = &kModelClassAssociatedKey;
- (void)setModelClass:(Class)cls {
    objc_setAssociatedObject(self, kModelClassAssociatedKey, cls, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (Class)modelClass {
    return objc_getAssociatedObject(self, kModelClassAssociatedKey);
}

- (ALSQLSelectCommand *_Nonnull(^_Nonnull)(Class _Nonnull modelClass))APPLY_MODEL {
    return ^ALSQLSelectCommand *_Nonnull(Class _Nonnull modelClass) {
        [self setModelClass:modelClass];
        return self;
    };
}

- (void)fetchWithCompletion:(void (^_Nullable)(FMResultSet *_Nullable rs))completion {
    FMResultSet *rs = self.EXECUTE_QUERY();
    if (completion != nil) {
        completion(rs);
    }
}

- (NSArray<__kindof ALModel *> *_Nullable (^)(void))FETCH_MODELS {
    return ^NSArray<__kindof ALModel *> *_Nullable(void) {
        self.SELECT(@[kRowIdColumnName, @"*"]);
        FMResultSet *rs = self.EXECUTE_QUERY();
        return modelsFromResultSet(rs, [self modelClass]);
    };
}

@end


@implementation ALModel (ActiveRecord)

@dynamic rowid;

static const void * const kModelFromDBAssociatedKey = &kModelFromDBAssociatedKey;
- (void)markModelFromDB:(BOOL)fromDB {
    objc_setAssociatedObject(self, kModelFromDBAssociatedKey, @(fromDB), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isModelFromDB {
    return [objc_getAssociatedObject(self, kModelFromDBAssociatedKey) boolValue];;
}

static const void *const kRowIDAssociatedKey = &kRowIDAssociatedKey;
- (NSInteger)rowid {
    return [objc_getAssociatedObject(self, &kRowIDAssociatedKey) integerValue];
}

- (void)setRowid:(NSInteger)rowId {
    NSAssert([self isModelFromDB], @"rowid CAN ONLY be set when this model is load from database!");
    objc_setAssociatedObject(self, &kRowIDAssociatedKey, @(rowId), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (nullable NSString *)tableName {
    return [self.class tableName];
}

+ (NSDictionary<NSString *, ALDBColumnInfo *> *)columns {
    static NSDictionary *columns = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *list    = nil;
        NSSet *blacklist = (list = [self recordPropertyBlacklist]) ? [NSSet setWithArray:list] : nil;
        NSSet *whitelist = (list = [self recordPropertyWhitelist]) ? [NSSet setWithArray:list] : nil;
        columns = [[[self allModelProperties] bk_select:^BOOL(NSString *key, YYClassPropertyInfo *p) {
            if (![self withoudRowId] && [key isEqualToString:keypathForClass(ALModel, rowid)]) {
                return YES;
            }
            if ([blacklist containsObject:key]) { return NO; }
            return whitelist == nil || [whitelist containsObject:key];
        }] bk_map:^ALDBColumnInfo *(NSString *key, YYClassPropertyInfo *p) {
            ALDBColumnInfo *colum = [[ALDBColumnInfo alloc] init];
            colum.property        = p;
            colum.name            = [self mappedColumnNameForProperty:key];
            colum.dataType        = suggestedSqliteDataType(p) ?: @"BLOB";
            [self customColumnDefine:colum forProperty:p];
            return colum;
        }];
    });
    return columns;
}

+ (NSString *)mappedColumnNameForProperty:(NSString *)propertyName {
    return [self modelCustomColumnNameMapper][propertyName] ?: [propertyName stringByConvertingCamelCaseToUnderscore];
}

- (nullable ALDatabase *)DB {
    return [self.class DB];
}

+ (nullable ALDatabase *)DB {
    return [ALDatabase databaseWithPath:[self databaseIdentifier]];
}

+ (nullable NSArray<__kindof ALModel *> *)modelsWithCondition:(nullable ALSQLCondition *)condition {
    NSArray *selectingColumns = nil;
    if (![self withoudRowId]) {
        selectingColumns = @[ kRowIdColumnName, @"*" ];
    }
    FMResultSet *rs = self.DB.SELECT(selectingColumns).FROM([self tableName]).WHERE(condition).EXECUTE_QUERY();
    return modelsFromResultSet(rs, self);
}

+ (ALSQLSelectCommand *)fetcher {
    return self.DB.SELECT(@[kRowIdColumnName, @"*"]).FROM([self tableName]).APPLY_MODEL(self.class);
}

+ (ALSQLUpdateCommand *)updateExector {
    return self.DB.UPDATE([self tableName]);
}

- (BOOL)saveOrReplce:(BOOL)replaceExisted {
    return self.DB.INSERT([self tableName])
        .POLICY(replaceExisted ? kALDBConflictPolicyReplace : nil)
        .VALUES([self propertiesToSaved])
        .EXECUTE_UPDATE();
}

- (nullable NSDictionary<NSString *, id> *)propertiesToSaved {
    NSArray *properties = [[[self.class columns].allValues bk_map:^NSString *(ALDBColumnInfo *colinfo) {
        return colinfo.property.name;
    }] bk_reject:^BOOL(NSString *propertyName) {
        return unwrapNil(propertyName) == nil || [propertyName isEqualToString:keypath(self.rowid)];
    }];

    NSMutableDictionary *updateValues = [NSMutableDictionary dictionaryWithCapacity:properties.count];
    [properties bk_each:^(NSString *propertyName) {
        NSString *selectorName = [NSString
            stringWithFormat:@"customColumnValueTransformFrom%@",
                             [[propertyName substringToIndexSafety:1]
                                 stringByAppendingString:stringOrEmpty([propertyName substringFromIndexSafety:1])]];
        SEL selector = NSSelectorFromString(selectorName);
        id value = nil;
        if (selector != nil && [self respondsToSelector:selector]) {
            value = ((id (*)(id, SEL))(void *) objc_msgSend)((id)self, selector);
        } else {
            value = [self valueForKey:propertyName];
        }
        updateValues[[self.class mappedColumnNameForProperty:propertyName]] = value;
    }];
    return updateValues;
}

- (nullable ALSQLCondition *)defaultModelUpdateCondition {
    if (![self.class withoudRowId]) {
        if (self.rowid == 0) {
            NSAssert(NO, @"'rowid' is not specified. OR use '+updateProperties:withCondition:repleace:' insted.");
            return nil;
        }
        return EQ(kRowIdColumnName, @(self.rowid));
    } else {
        return [[[self.class primaryKeys] bk_map:^ALSQLCondition *(NSString *propertyName) {
            return [EQ([self.class mappedColumnNameForProperty:propertyName], [self valueForKey:propertyName]) build];
        }] bk_reduce:nil
            withBlock:^ALSQLCondition *(ALSQLCondition *result, ALSQLCondition *obj) {
                return result == nil ? [obj build] : result.AND(obj);
            }];
    }
}

- (BOOL)updateOrReplace:(BOOL)replaceExisted {
    ALSQLCondition *condition = [self defaultModelUpdateCondition];
    if (condition == nil) {
        return NO;
    }
    return self.DB.UPDATE([self tableName])
        .POLICY(replaceExisted ? kALDBConflictPolicyReplace : nil)
        .VALUES([self propertiesToSaved])
        .WHERE(condition)
        .EXECUTE_UPDATE();
}

- (BOOL)updateProperties:(NSArray<NSString *> *)properties repleace:(BOOL)replaceExisted {
    ALSQLCondition *condition = [self defaultModelUpdateCondition];
    if (condition == nil) {
        return NO;
    }

    NSMutableDictionary *updateValues = [NSMutableDictionary dictionaryWithCapacity:properties.count];
    [properties bk_each:^(NSString *propertyName) {
        updateValues[[self.class mappedColumnNameForProperty:propertyName]] = [self valueForKey:propertyName];
    }];
    return self.DB.UPDATE([self tableName])
        .POLICY(replaceExisted ? kALDBConflictPolicyReplace : nil)
        .VALUES(updateValues)
        .WHERE(condition)
        .EXECUTE_UPDATE();
}

- (BOOL)deleteRecord {
    if (![self isModelFromDB]) {
        return NO;
    }
    return self.DB.DELETE_FROM([self tableName]).WHERE([self defaultModelUpdateCondition]).EXECUTE_UPDATE();
}

+ (BOOL)saveRecords:(NSArray<ALModel *> *)models repleace:(BOOL)replaceExisted {
    [self.DB.queue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        [models bk_each:^(ALModel *obj) {
            [obj saveOrReplce:replaceExisted];
        }];
    }];
    return YES;
}

+ (BOOL)updateRecords:(NSArray<ALModel *> *)models replace:(BOOL)replaceExisted {
    [self.DB.queue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        [models bk_each:^(ALModel *obj) {
            [obj updateOrReplace:replaceExisted];
        }];
    }];
    return YES;
}

+ (BOOL)updateProperties:(NSDictionary *)contentValues
           withCondition:(nullable ALSQLCondition *)condition
                repleace:(BOOL)replaceExisted {
    __block BOOL ret = YES;
    [self.DB.queue inTransaction:^(FMDatabase *_Nonnull db, BOOL *_Nonnull rollback) {
        ret = self.DB.UPDATE([self tableName])
                  .POLICY(replaceExisted ? kALDBConflictPolicyReplace : nil)
                  .VALUES(contentValues)
                  .WHERE(condition)
                  .EXECUTE_UPDATE();
    }];
    return ret;
}

+ (BOOL)deleteRecordsWithCondition:(nullable ALSQLCondition *)condition {
    if (condition == nil) {
        ALLogWarn(@"condition is nil, DELETE ALL records");
    }

    return self.DB.DELETE_FROM([self tableName]).WHERE(condition).EXECUTE_UPDATE();
}

+ (NSString *)tableSchema {
    NSString *tableName = [[self tableName] stringify];
    if (tableName.length == 0) {
        return nil;
    }
    
    NSMutableString *sqlClause = [NSMutableString string];
    
    // CREATE TABLE
    [sqlClause appendFormat:@"CREATE TABLE IF NOT EXISTS %@ (", tableName];
    
    // COLUMN DEF
    [sqlClause appendString:[[[[[self columns] bk_reject:^BOOL(NSString *key, id obj) {
                                   return [key isEqualToString:keypathForClass(ALModel, rowid)];
                               }].allValues sortedArrayUsingComparator:[self columnOrderComparator]]
                                bk_map:^NSString *(ALDBColumnInfo *column) {
                                    return [column columnDefine];
                                }] componentsJoinedByString:@", "]];

    // PRIMARY KEY
    NSArray *indexKeys = [[self primaryKeys] bk_map:^NSString *(NSString *propertyName) {
        return [self mappedColumnNameForProperty:propertyName];
    }];
    if ([indexKeys count] > 0) {
        [sqlClause appendFormat:@", PRIMARY KEY (%@)", [indexKeys componentsJoinedByString:@", "]];
    }

    [sqlClause appendString:@")"];
    
    if ([self withoudRowId]) {
        [sqlClause appendString:@"WITHOUT ROWID"];
    }
    
    return [sqlClause copy];
}

+ (NSArray<NSString *> *)indexStatements {
    NSMutableArray *stmts = [NSMutableArray array];
    NSArray *array = [self indexeStatementWithKeys:[self uniqueKeys] unique:YES];
    if (array.count > 0) {
        [stmts addObjectsFromArray:array];
    }
    
    array = [self indexeStatementWithKeys:[self indexKeys] unique:NO];
    if (array.count > 0) {
        [stmts addObjectsFromArray:array];
    }
    return stmts;
}

+ (nullable NSArray<NSString *> *)indexeStatementWithKeys:(nullable NSArray<NSArray<NSString *> *> *)indexKeys
                                                   unique:(BOOL)unique {
    if ([indexKeys count] > 0) {
        NSString *tableName = [[self tableName] stringify];
        
        return [[indexKeys bk_reject:^BOOL(NSArray<NSString *> *cols) {
            return ![cols isKindOfClass:[NSArray class]] || cols.count == 0;
        }] bk_map:^NSString *(NSArray<NSString *> *cols) {
            cols = [cols bk_map:^NSString *(NSString *pn) {
                return [self mappedColumnNameForProperty:pn];
            }];
            NSString *idxName = [cols componentsJoinedByString:@"_"];
            idxName           = [(unique ? @"uniq_" : @"idx_") stringByAppendingString:idxName];
            NSString *idxVal  = [cols componentsJoinedByString:@", "];
            
            return [NSString
                    stringWithFormat:@"CREATE UNIQUE INDEX IF NOT EXISTS %@ ON %@(%@)", idxName, tableName, idxVal];
        }];
    }
    return nil;
}

@end


@implementation ALModel (ActiveRecord_Protected)

+ (nullable NSString *)tableName {
    return self.description;
}

+ (nullable NSString *)databaseIdentifier {
    return nil;
}

+ (nullable NSArray<NSString *> *)recordPropertyBlacklist {
    return [ALOCRuntime propertiesOfProtocol:@protocol(NSObject)].allKeys;
}

+ (nullable NSArray<NSString *> *)recordPropertyWhitelist {
    return nil;
}

+ (nullable NSDictionary<NSString *, NSString *>  *)modelCustomColumnNameMapper {
    return nil;
}

+ (NSComparator)columnOrderComparator {
    return ^NSComparisonResult(ALDBColumnInfo *_Nonnull col1, ALDBColumnInfo *_Nonnull col2) {
        NSArray *list = [self recordPropertyWhitelist] ?: [[@[
            wrapNil([self primaryKeys]),
            wrapNil([[self uniqueKeys] al_flatten]),
            wrapNil([[self indexKeys] al_flatten])
        ] bk_reject:^BOOL(id obj) {
            return obj == NSNull.null;
        }] al_flatten];

        NSOrderedSet *orderedSet = [NSOrderedSet orderedSetWithArray:list];

        NSInteger idx1 = [orderedSet indexOfObject:col1.property.name];
        NSInteger idx2 = [orderedSet indexOfObject:col2.property.name];
        if (idx1 != NSNotFound && idx2 != NSNotFound) {
            return [@(idx1) compare:@(idx2)];
        } else if (idx1 != NSNotFound) {
            return NSOrderedAscending;
        } else if (idx2 != NSNotFound) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    };
}

+ (void)customColumnDefine:(ALDBColumnInfo *)cloumn forProperty:(in YYClassPropertyInfo *)property {
}

+ (nullable NSArray<NSString *> *)primaryKeys {
    return nil;
}

+ (nullable NSArray<NSArray<NSString *> *> *)uniqueKeys {
    return nil;
}

+ (nullable NSArray<NSArray<NSString *> *> *)indexKeys {
    return nil;
}

+ (BOOL)withoudRowId {
    return NO;
}


@end

/**
 * @see https://www.sqlite.org/datatype3.html
 */
static FORCE_INLINE NSString * suggestedSqliteDataType(YYClassPropertyInfo *property) {
    
    switch (property.type & YYEncodingTypeMask) {
        case YYEncodingTypeBool:
        case YYEncodingTypeInt8:
        case YYEncodingTypeUInt8:
        case YYEncodingTypeInt16:
        case YYEncodingTypeUInt16:
        case YYEncodingTypeInt32:
        case YYEncodingTypeUInt32:
        case YYEncodingTypeInt64:
        case YYEncodingTypeUInt64:
            return @"INTEGER";
            
        case YYEncodingTypeFloat:
        case YYEncodingTypeDouble:
        case YYEncodingTypeLongDouble:
            return @"REAL";
            
        default: break;
    }
    
    if ([property.cls isSubclassOfClass:[NSString class]] ||
        [property.cls isSubclassOfClass:[NSURL class]]) {
        return @"TEXT";
    }
    if ([property.cls isSubclassOfClass:[NSData class]]) {
        return @"BLOB";
    }
    if ([property.cls isSubclassOfClass:[NSDate class]]) {
        return @"DATETIME"; //REAL
    }
    if ([property.cls isSubclassOfClass:[NSNumber class]]) {
        return @"NUMERIC";
    }
    
    return @"BLOB";
    
}

@interface _ColumnPropertyInfo : NSObject {
    @package
    YYClassPropertyInfo *_property;
    SEL                  _customSetter;
    SEL                  _customGetter;
}

@end

@implementation _ColumnPropertyInfo
@end

static FORCE_INLINE void setModelPropertyValueFromResultSet(FMResultSet *rs, int columnIndex, ALModel *model,
                                                            _ColumnPropertyInfo *propertyInfo) {
    YYClassPropertyInfo *property = propertyInfo->_property;
    if (propertyInfo->_customSetter != nil) {
        // customTransform{PropertyName}FromRecord:columnIndex:
        ((void (*)(id, SEL, id, int))(void *) objc_msgSend)((id) model, propertyInfo->_customSetter, (id) rs,
                                                            columnIndex);
        return;
    }

    if (property.setter == nil) {
        return;
    }
    SEL setter = property.setter;
    switch (property.type & YYEncodingTypeMask) {
        case YYEncodingTypeBool:  ///< bool
            ((void (*)(id, SEL, bool))(void *) objc_msgSend)((id) model, setter, [rs boolForColumnIndex:columnIndex]);
            break;

        case YYEncodingTypeInt8:   ///< char / BOOL
        case YYEncodingTypeInt16:  ///< short
        case YYEncodingTypeInt32:  ///< int
            ((void (*)(id, SEL, int))(void *) objc_msgSend)((id) model, setter, [rs intForColumnIndex:columnIndex]);
            break;

        case YYEncodingTypeUInt8:   ///< unsigned char
        case YYEncodingTypeUInt16:  ///< unsigned short
        case YYEncodingTypeUInt32:  ///< unsigned int
            ((void (*)(id, SEL, uint))(void *) objc_msgSend)((id) model, setter,
                                                             (uint) [rs intForColumnIndex:columnIndex]);
            break;

        case YYEncodingTypeInt64:  ///< long long
            ((void (*)(id, SEL, long long))(void *) objc_msgSend)((id) model, setter,
                                                                  [rs longLongIntForColumnIndex:columnIndex]);
            break;

        case YYEncodingTypeUInt64:  ///< unsigned long long
            ((void (*)(id, SEL, unsigned long long))(void *) objc_msgSend)(
                (id) model, setter, [rs unsignedLongLongIntForColumnIndex:columnIndex]);
            break;

        case YYEncodingTypeFloat:       ///< float
        case YYEncodingTypeDouble:      ///< double
        case YYEncodingTypeLongDouble:  ///< long double
            ((void (*)(id, SEL, CGFloat))(void *) objc_msgSend)((id) model, setter,
                                                                [rs doubleForColumnIndex:columnIndex]);
            break;

        default: {
            id value = nil;
            if ([property.cls isSubclassOfClass:[NSString class]]) {
                value = [rs stringForColumnIndex:columnIndex];
            } else if ([property.cls isSubclassOfClass:[NSMutableString class]]) {
                value = [[rs stringForColumnIndex:columnIndex] mutableCopy];
            } else if ([property.cls isSubclassOfClass:[NSURL class]]) {
                value = [rs stringForColumnIndex:columnIndex];
            } else if ([property.cls isSubclassOfClass:[NSNumber class]]) {
                int columnType = sqlite3_column_type([rs.statement statement], columnIndex);
                if (columnType == SQLITE_INTEGER) {
                    value = @([rs longLongIntForColumnIndex:columnIndex]);
                } else {
                    value = @([rs doubleForColumnIndex:columnIndex]);
                }
            } else if ([property.cls isSubclassOfClass:[NSMutableData class]]) {
                value = [[rs dataForColumnIndex:columnIndex] mutableCopy];
            } else if ([property.cls isSubclassOfClass:[NSData class]]) {
                value = [rs dataForColumnIndex:columnIndex];
            } else if ([property.cls isSubclassOfClass:[NSDate class]]) {
                value = [rs dateForColumnIndex:columnIndex];
            } else if ([property.cls isSubclassOfClass:[NSMutableArray class]] ||
                       [property.cls isSubclassOfClass:[NSMutableDictionary class]] ||
                       [property.cls isSubclassOfClass:[NSMutableSet class]]) {
                value = [rs dataForColumnIndex:columnIndex];
                if (value != nil) {
                    @try {
                        value = [NSKeyedUnarchiver unarchiveObjectWithData:value];
                    } @catch (NSException *exception) {
                        ALLogWarn(@"Exception: %@", exception);
                        value = nil;
                    }
                    value = [value mutableCopy];
                }

            } else {
                value = [rs dataForColumnIndex:columnIndex];
                if (value != nil) {
                    @try {
                        value = [NSKeyedUnarchiver unarchiveObjectWithData:value];
                    } @catch (NSException *exception) {
                        ALLogWarn(@"Exception: %@", exception);
                        value = nil;
                    }
                }
            }

            if (value == NSNull.null) {
                value = nil;
            }
            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, setter, value);
        } break;
    }
}

static FORCE_INLINE void constructModelFromResultSet(FMResultSet *rs, ALModel *model,
                                                     NSDictionary<NSString *, id> *columnPropertyMapper) {
    
    [model markModelFromDB:YES];
    [columnPropertyMapper bk_each:^(NSString *colName, id obj) {
        if ([colName.lowercaseString isEqualToString:kRowIdColumnName]) {
            [model setRowid:[rs intForColumn:colName]];
            return;
        }
        int idx = [rs columnIndexForName:colName];
        if ([obj isKindOfClass:[_ColumnPropertyInfo class]]) {
            setModelPropertyValueFromResultSet(rs, idx, model, (_ColumnPropertyInfo *)obj);
        } else if ([obj isKindOfClass:[NSArray class]]) {
            [(NSArray *)obj bk_each:^(_ColumnPropertyInfo *obj) {
                setModelPropertyValueFromResultSet(rs, idx, model, (_ColumnPropertyInfo *)obj);
            }];
        }
    }];
}

static FORCE_INLINE NSArray<__kindof ALModel *> *_Nullable modelsFromResultSet(FMResultSet *rs, Class modelClass) {
    if (rs == nil || ![modelClass isSubclassOfClass:[ALModel class]] || rs.columnCount == 0) {
        return nil;
    }
    
    NSMutableSet *columnNames = [NSMutableSet setWithCapacity:rs.columnCount];
    for (int idx = 0; idx < rs.columnCount; ++idx) {
        [columnNames addObject:[rs columnNameForIndex:idx]];
    }
    
    NSMutableDictionary *columnPropertyMapper = [NSMutableDictionary dictionary];
    [[modelClass columns] bk_each:^(NSString *propertyName, ALDBColumnInfo *colInfo) {
        NSString *mappedColName = [modelClass mappedColumnNameForProperty:propertyName];
        if (![columnNames containsObject:mappedColName]) {
            return;
        }

        NSString *firstUpperPropertyName = [[propertyName substringToIndexSafety:1]
            stringByAppendingString:stringOrEmpty([propertyName substringFromIndexSafety:1])];
        NSString *customSetterName =
            [NSString stringWithFormat:@"customTransform%@FromRecord:columnIndex:", firstUpperPropertyName];
        SEL customSetter = NSSelectorFromString(customSetterName);

        _ColumnPropertyInfo *cpi = [[_ColumnPropertyInfo alloc] init];
        cpi->_property = colInfo.property;
        if (customSetter != nil && [modelClass instancesRespondToSelector:customSetter]) {
            cpi->_customSetter = customSetter;
        }

        id obj = columnPropertyMapper[mappedColName];
        if ([obj isKindOfClass:[NSMutableArray class]]) {
            [(NSMutableArray *) obj addObject:cpi];
        } else if (obj != nil) {
            columnPropertyMapper[mappedColName] = [@[ obj, cpi ] mutableCopy];
        } else {
            columnPropertyMapper[mappedColName] = cpi;
        }
    }];

    NSMutableArray *models = [NSMutableArray array];
    while ([rs next]) {
        ALModel *oneModel = [[modelClass alloc] init];
        constructModelFromResultSet(rs, oneModel, columnPropertyMapper);
        [models addObject:oneModel];
    }
    
    return [models copy];
}



