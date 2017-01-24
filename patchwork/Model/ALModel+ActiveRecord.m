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
#import "ALOCRuntime.h"
#import <sqlite3.h>
#import <objc/message.h>
#import "SafeBlocksChain.h"
#import "ALSQLStatementHelpers_private.h"
#import "ALSQLClause+SQLOperation.h"
#import <ObjcAssociatedObjectHelpers.h>
#import "ALLogger.h"
#import "ActiveRecordAdditions.h"
#import "MD5.h"
#import "NSObject+JSONTransform.h"
#import "ALLock.h"

NSString * const kRowIdColumnName = @"rowid";

#pragma mark - utilities functions
static AL_FORCE_INLINE NSString * suggestedSqliteDataType(YYClassPropertyInfo *property);

static AL_FORCE_INLINE void setModelPropertyValueFromResultSet(FMResultSet *rs,
                                                            int             columnIndex,
                                                            ALModel        *model,
                                                            ALDBColumnInfo *colinfo);

static AL_FORCE_INLINE NSArray<__kindof ALModel *> *_Nullable modelsFromResultSet(FMResultSet *rs, Class modelClass);
static AL_FORCE_INLINE NSDictionary<NSString * /*colname*/, NSArray<ALDBColumnInfo *> *> *modelColumnPropertyMapper(
                    FMResultSet *rs, Class modelClass);
static AL_FORCE_INLINE void setModelPropertyValueWithResultSet(FMResultSet *rs, ALModel *oneModel,
                                                            NSDictionary * columnPropertyMapper);
// column value saving to DB
static AL_FORCE_INLINE id _Nullable modelColumnValue(ALModel *_Nonnull model, ALDBColumnInfo *_Nonnull colInfo);


#pragma mark -
@interface ALDBColumnInfo (ALModelCustomColumnValueTransformer)
// "customPropertyToColumnValueTransformer" points to SEL "-customColumnValueTransForm{PropertyName}"
@property(nonatomic, assign) SEL customPropertyToColumnValueTransformer;
// "customPropertyFromColumnValueTransformer" points to SEL "-customTransform{PropertyName}FromRecord:columnIndex:"
@property(nonatomic, assign) SEL customPropertyFromColumnValueTransformer;
@end

@implementation ALDBColumnInfo (ALModelCustomColumnValueTransformer)

SYNTHESIZE_ASC_PRIMITIVE(customPropertyToColumnValueTransformer, setCustomPropertyToColumnValueTransformer, SEL);
SYNTHESIZE_ASC_PRIMITIVE(customPropertyFromColumnValueTransformer, setCustomPropertyFromColumnValueTransformer, SEL);

@end


#pragma mark -
@implementation ALSQLSelectStatement (ActiveRecord)

SYNTHESIZE_ASC_OBJ(modelClass, setModelClass);

- (ALSQLSelectStatement *(^)(__unsafe_unretained Class modelClass))APPLY_MODEL {
    return ^ALSQLSelectStatement *(__unsafe_unretained Class modelClass) {
        __ALSQLSTMT_BLOCK_CHAIN_OBJ_VERIFY();
        
        [self setModelClass:modelClass];
        return self;
    };
}

- (NSArray<__kindof ALModel *> *_Nullable (^)(void))FETCH_MODELS {
    return ^NSArray<__kindof ALModel *> *_Nullable(void) {
        ValidBlocksChainObjectOrReturn(self, nil);
        
        __block NSArray *models = nil;
        self.SELECT(@[kRowIdColumnName, @"*"]).EXECUTE_QUERY(^(FMResultSet *rs){
            models = modelsFromResultSet(rs, [self modelClass]);
        });
        return models;
    };
}

@end


#pragma mark -
#if DEBUG
#define __verify_rowid_alias_type(cls)  \
    if ([(cls) hasRowidAlias]) {        \
        NSString *aliasName = [(cls) rowidAliasPropertyName];                   \
        YYClassPropertyInfo *p = [self.class allModelProperties][aliasName];    \
        NSAssert(p != nil, @"*** %@: not found rowid's alias named '%@'", NSStringFromClass(cls), aliasName);   \
                                                                                \
        YYEncodingType type = p.type & YYEncodingTypeMask;                      \
        NSAssert(type == YYEncodingTypeInt8  ||                                 \
                type == YYEncodingTypeUInt8  ||                                 \
                type == YYEncodingTypeInt16  ||                                 \
                type == YYEncodingTypeUInt16 ||                                 \
                type == YYEncodingTypeInt32  ||                                 \
                type == YYEncodingTypeUInt32 ||                                 \
                type == YYEncodingTypeInt64  ||                                 \
                type == YYEncodingTypeUInt64,                                   \
        @"property '%@' should be type of NSInteger", aliasName);               \
    }
#else
    #define __verify_rowid_alias_type(cls)     do{}while(0)
#endif

static ALDatabase *SafeDB(ALDatabase *db) {
    db = SafeBlocksChainObj(db, ALDatabase);
    NSCAssert(db != nil, @"*** db is nil!!!");
    return db;
}

@implementation ALModel (ActiveRecord)

@dynamic rowid;

#pragma mark associated properties

SYNTHESIZE_ASC_PRIMITIVE(isModelFromDB, markModelFromDB, BOOL);
SYNTHESIZE_ASC_PRIMITIVE(rowid, setRowid, NSInteger);

#pragma mark - rowid change notification
- (void)handleRecordConflictNotification:(NSNotification *)note {
    if (note.object == self.class && [self isModelFromDB] && ![self.class withoutRowId]) {
        NSDictionary *updatedModelsDict = note.userInfo;
        [[self.class uniqueKeys]
            enumerateObjectsUsingBlock:^(NSArray<NSString *> *_Nonnull unikey, NSUInteger idx, BOOL *_Nonnull stop) {
                NSString *hash = [self valuesHashWithProperties:unikey];
                NSAssert(hash != nil, @"*** model [%@] hash value is nil! Unique keys:(%@)", self.class,
                         [unikey componentsJoinedByString:@", "]);
                ALModel *updatedModel = updatedModelsDict[hash];
                if (updatedModel.class == self.class) {
                    self.rowid = updatedModel.rowid;
                }
            }];
    }
}


+ (void)notifyModelsRowidDidChange:(NSArray<ALModel *> *)updatedModels {
    if (updatedModels.count == 0) {
        return;
    }
    
    Class type = updatedModels.firstObject.class;
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSArray<NSArray<NSString *> *> *uniqueKeys = [type uniqueKeys];
    [updatedModels bk_each:^(ALModel *model) {
        [uniqueKeys bk_each:^(NSArray<NSString *> *properties) {
            NSString *hash = [model valuesHashWithProperties:properties];
            if (hash != nil) {
                dict[hash] = model;
            } else {
                NSAssert(NO, @"*** model [%@] hash value is nil! Unique keys:(%@)", model.class,
                         [properties componentsJoinedByString:@", "]);
            }
        }];
    }];
    if (dict.count == 0) {
        return;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kModelRowidDidChangeNotification
                                                        object:type
                                                      userInfo:dict];
}

- (NSString *)valuesHashWithProperties:(NSArray<NSString *> *)properties {
    NSDictionary *columns = [self.class tableColumns];
    
    NSMutableDictionary *valDict = [NSMutableDictionary dictionaryWithCapacity:properties.count];
    [properties bk_each:^(NSString *name) {
        id val = modelColumnValue(self, columns[name]);
        if (val != nil) {
            valDict[name] = val;
        }
    }];
    
    return [[valDict JSONData] MD5];
}

#pragma mark -
+ (nullable NSString *)rowidAliasPropertyName { return nil; }
+ (BOOL)hasRowidAlias { return NO; }

#pragma mark -
- (nullable NSString *)tableName {
    return [self.class tableName];
}

+ (NSDictionary<NSString *, ALDBColumnInfo *> *)tableColumns {
    // modelsColumnsDict: @{ClassName: @{propertyName: columnInfo}}
    static NSMutableDictionary<NSString *, NSDictionary<NSString *, ALDBColumnInfo *> *> *modelsColumnsDict = nil;
    static dispatch_once_t onceToken1;
    static dispatch_semaphore_t localSema;
    dispatch_once(&onceToken1, ^{
        modelsColumnsDict = [NSMutableDictionary dictionary];
        localSema = dispatch_semaphore_create(1);
    });
    
    NSString *className = NSStringFromClass(self);
    __block NSDictionary *columns = nil;
    with_gcd_semaphore(localSema, DISPATCH_TIME_FOREVER, ^{
        columns = modelsColumnsDict[className];
        if (columns == nil) {
            __verify_rowid_alias_type(self);
            
            NSArray *list    = nil;
            NSSet *blacklist = (list = [self recordPropertyBlacklist]) ? [NSSet setWithArray:list] : nil;
            NSSet *whitelist = (list = [self recordPropertyWhitelist]) ? [NSSet setWithArray:list] : nil;
            columns = [[[self allModelProperties] bk_select:^BOOL(NSString *key, YYClassPropertyInfo *p) {
                if (![self withoutRowId] && [key isEqualToString:keypathForClass(ALModel, rowid)]) {
                    return YES;
                }
                if ([blacklist containsObject:key]) { return NO; }
                return whitelist == nil || [whitelist containsObject:key];
            }] bk_map:^ALDBColumnInfo *(NSString *key, YYClassPropertyInfo *p) {
                ALDBColumnInfo *colum = [[ALDBColumnInfo alloc] init];
                colum.property        = p;
                colum.name            = [self mappedColumnNameForProperty:key];
                colum.type            = suggestedSqliteDataType(p) ?: @"BLOB";
                [self customColumnDefine:colum forProperty:p];
                [self bindCustomPropertyValueTransformerForColumn:colum];
                return colum;
            }];
            modelsColumnsDict[className] = columns;
        }
    });
    return columns;
}

+ (void)bindCustomPropertyValueTransformerForColumn:(ALDBColumnInfo *)colInfo {
    NSString *propertyName            = colInfo.property.name;
    NSString *capitalizedPropertyName = [propertyName stringbyUppercaseFirst];
    
    SEL toColumnValueSEL =
        NSSelectorFromString([@"customColumnValueTransForm" stringByAppendingString:capitalizedPropertyName]);
    if (toColumnValueSEL != nil && [self instancesRespondToSelector:toColumnValueSEL]) {
        colInfo.customPropertyToColumnValueTransformer = toColumnValueSEL;
    }

    SEL fromColumnValueSEL = NSSelectorFromString(
        [NSString stringWithFormat:@"customTransform%@FromRecord:columnIndex:", capitalizedPropertyName]);
    if (fromColumnValueSEL != nil && [self instancesRespondToSelector:fromColumnValueSEL]) {
        colInfo.customPropertyFromColumnValueTransformer = fromColumnValueSEL;
    }
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


+ (ALSQLSelectStatement *)fetcher {
    return SafeDB([self DB]).SELECT(@[kRowIdColumnName, @"*"]).FROM([self tableName]).APPLY_MODEL(self.class);
}

+ (ALSQLUpdateStatement *)updateExector {
    return SafeDB([self DB]).UPDATE([self tableName]);
}


+ (void)inTransaction:(void(^)(ALDatabase *bindingDB, BOOL *rollback))transaction {
    [[self DB].queue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        safeInvokeBlock(transaction, [self DB], rollback);
    }];
}

+ (void)inDeferredTransaction:(void(^)(ALDatabase *bindingDB, BOOL *rollback))transaction {
    [[self DB].queue inDeferredTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        safeInvokeBlock(transaction, [self DB], rollback);
    }];
}

+ (void)inDatabase:(void(^)(ALDatabase *bindingDB))task {
    [[self DB].queue inDatabase:^(FMDatabase * _Nonnull db) {
        safeInvokeBlock(task, [self DB]);
    }];
}


- (void)inTransaction:(void(^)(ALDatabase *bindingDB, BOOL *rollback))transaction {
    [self.class inTransaction:transaction];
}

- (void)inDeferredTransaction:(void(^)(ALDatabase *bindingDB, BOOL *rollback))transaction {
    [self.class inDeferredTransaction:transaction];
}

- (void)inDatabase:(void(^)(ALDatabase *bindingDB))task {
    [self.class inDatabase:task];
}


+ (nullable NSArray<__kindof ALModel *> *)modelsWithCondition:(nullable ALSQLClause *)conditions {
    NSArray *selectingColumns = nil;
    if (![self withoutRowId]) {
        selectingColumns = @[ kRowIdColumnName, @"*" ];
    }
    
    __block NSArray *models = nil;
    SafeDB([self DB]).SELECT(selectingColumns).FROM([self tableName]).WHERE(conditions).EXECUTE_QUERY(^(FMResultSet *rs) {
        if (rs != nil) {
            models = modelsFromResultSet(rs, self);
        }
    });
    return models;
}

+ (nullable ALModel *)modelWithId:(NSInteger)rowid {
    return [self modelsWithCondition:kRowIdColumnName.EQ(@(rowid))].firstObject;
}

- (BOOL)reload {
    __block BOOL result = NO;
    
    void (^fetchModel)(FMResultSet *rs) = ^(FMResultSet *rs) {
        if ([rs next]) {
            NSDictionary *mapper = modelColumnPropertyMapper(rs, self.class);
            setModelPropertyValueWithResultSet(rs, self, mapper);
            result = YES;
        }
    };
    
    // 1, try query using rowid
    SafeDB([self DB])
        .SELECT(@[ kRowIdColumnName, @"*" ])
        .FROM([self tableName])
        .WHERE(AS_COL(ALModel, rowid).EQ(@(self.rowid)))
        .EXECUTE_QUERY(fetchModel);
    
    // 2, try query using primary key
    if (!result && ![self.class hasRowidAlias]) {
        NSArray *primaryKeys = [self.class primaryKeys];
        if (primaryKeys.count == 0) {
            return NO;
        }
        // if validate failed, return NO;
        validatePropertyColumnMappings(self.class, primaryKeys, NO);
        
        SafeDB([self DB])
            .SELECT(@[ kRowIdColumnName, @"*" ])
            .FROM([self tableName])
            .WHERE([primaryKeys bk_reduce:nil withBlock:^ALSQLClause *(ALSQLClause *sum, NSString *p) {
                NSString *colname = [self.class mappedColumnNameForProperty:p];
                ALSQLClause *and = colname.EQ([self valueForKey:p]);
                return sum == nil ? and : sum.AND(and);
            }]).EXECUTE_QUERY(fetchModel);
        
    }
    //TODO? if rowid not matches, should it update via unique-keys?
    return result;
}

- (nullable NSDictionary<NSString *, id> *)propertiesToSaved {
    NSDictionary<NSString *, ALDBColumnInfo *> *columns = [self.class tableColumns];
    NSMutableDictionary *updateValues = [NSMutableDictionary dictionaryWithCapacity:columns.count];
    [columns.allValues bk_each:^(ALDBColumnInfo *colInfo) {
        NSString *colname = colInfo.name;
        id val = modelColumnValue(self, colInfo);
        if (val != nil) {
            updateValues[colname] = val;
        }
    }];
    return updateValues;
}

- (NSInteger)saveOrReplce:(BOOL)replaceExisted {
    __block NSInteger lastInsertRowid = 0;
    NSInteger oldRowid = self.rowid;
    [self.DB.queue inDatabase:^(FMDatabase *_Nonnull db) {
        BOOL result = SafeDB([self DB])
                     .INSERT()
                     .OR_REPLACE(replaceExisted)
                     .INTO([self tableName])
                     .VALUES_DICT([self propertiesToSaved])
                     .EXECUTE_UPDATE();
        if (result) {
            lastInsertRowid = [db lastInsertRowId];
            self.rowid = lastInsertRowid;
            [self markModelFromDB:YES];
        }
    }];
    if (self.rowid != oldRowid) {
        [self.class notifyModelsRowidDidChange:@[self]];
    }

    return lastInsertRowid;
}

+ (BOOL)saveRecords:(NSArray<ALModel *> *)models repleace:(BOOL)replaceExisted {
    if (self.DB == nil) {
        NSAssert(NO, @"model [%@] database is nil!", self);
        return NO;
    }

    __block BOOL hasError = NO;
    NSMutableDictionary *rowIdsDict = [NSMutableDictionary dictionaryWithCapacity:models.count];
    [self.DB.queue inTransaction:^(FMDatabase *_Nonnull db, BOOL *_Nonnull rollback) {
        [models enumerateObjectsUsingBlock:^(ALModel *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            BOOL result = SafeDB([self DB])
                              .INSERT()
                              .OR_REPLACE(replaceExisted)
                              .INTO([self tableName])
                              .VALUES_DICT([obj propertiesToSaved])
                              .EXECUTE_UPDATE();

            if (result) {
                NSInteger lastId = [db lastInsertRowId];
                if (obj.rowid != lastId) {
                    rowIdsDict[@(obj.rowid)] = @(lastId);
                }
            } else {
                hasError  = YES;
                *rollback = YES;
                *stop     = YES;
            }
        }];
    }];
    // if transactions commit, update model's rowid
    if (!hasError) {
        [models enumerateObjectsUsingBlock:^(ALModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.rowid = [rowIdsDict[@(obj.rowid)] integerValue];
            [obj markModelFromDB:YES];
        }];
        
        [self notifyModelsRowidDidChange:models];
    }
    
    return !hasError;
}

- (nullable ALSQLClause *)defaultModelUpdateCondition {
    if (![self.class withoutRowId]) {
        if (self.rowid == 0) {
            NSAssert(NO, @"'rowid' is not specified. OR use '+updateProperties:withCondition:repleace:' insted.");
            return nil;
        }
        return kRowIdColumnName.EQ(@(self.rowid));
    } else {
        return [[self.class primaryKeys]
            bk_reduce:nil
            withBlock:^ALSQLClause *(ALSQLClause *sum, NSString *propertyName) {
                ALSQLClause *clause =
                    [self.class mappedColumnNameForProperty:propertyName].EQ([self valueForKey:propertyName]);
                return sum == nil ? clause : sum.AND(clause);
            }];
    }
}

- (BOOL)updateOrReplace:(BOOL)replaceExisted {
    return [self updateWithDictionary:[self propertiesToSaved] repleace:replaceExisted];
}

- (BOOL)updateProperties:(nullable NSArray<NSString *> *)properties repleace:(BOOL)replaceExisted {
    
    NSMutableDictionary *updateValues = [NSMutableDictionary dictionaryWithCapacity:properties.count];
    [properties bk_each:^(NSString *propertyName) {
        updateValues[[self.class mappedColumnNameForProperty:propertyName]] = wrapNil([self valueForKey:propertyName]);
    }];
    return [self updateWithDictionary:updateValues repleace:replaceExisted];
}

- (BOOL)updateWithDictionary:(NSDictionary *)contentsDict repleace:(BOOL)replaceExisted {
    ALSQLClause *condition = [self defaultModelUpdateCondition];
    if (condition == nil) {
        return NO;
    }

    return SafeDB([self DB])
        .UPDATE([self tableName])
        .OR_REPLACE(replaceExisted)
        .SET(contentsDict)
        .WHERE(condition)
        .EXECUTE_UPDATE();
}

- (BOOL)deleteRecord {
    return SafeDB([self DB]).DELETE().FROM([self tableName]).WHERE([self defaultModelUpdateCondition]).EXECUTE_UPDATE();
}

+ (BOOL)updateRecords:(NSArray<ALModel *> *)models replace:(BOOL)replaceExisted {
    __block BOOL result = YES;
    [self.DB.queue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        [models enumerateObjectsUsingBlock:^(ALModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (![obj updateOrReplace:replaceExisted]) {
                result = NO;
                *rollback = YES;
                *stop = YES;
            }
        }];
    }];
    return result;
}

+ (BOOL)updateProperties:(NSDictionary *)contentValues
           withCondition:(nullable ALSQLClause *)condition
                repleace:(BOOL)replaceExisted {
    NSMutableDictionary *updateValues = [NSMutableDictionary dictionaryWithCapacity:contentValues.count];
    [contentValues bk_each:^(NSString *propertyName, id value) {
        updateValues[[self mappedColumnNameForProperty:propertyName]] = value;
    }];

    return SafeDB([self DB])
        .UPDATE([self tableName])
        .OR_REPLACE(replaceExisted)
        .SET(updateValues)
        .WHERE(condition)
        .EXECUTE_UPDATE();
}

+ (BOOL)deleteRecordsWithCondition:(nullable ALSQLClause *)condition {
    if (condition == nil) {
        ALLogWarn(@"condition is nil, DELETE ALL records");
    }
    
    return SafeDB([self DB]).DELETE().FROM([self tableName]).WHERE(condition).EXECUTE_UPDATE();
}

@end


#import "NSCache+ALExtensions.h"
#import "ALStringInflector.h"

@implementation ALModel (ActiveRecord_Protected)

+ (nullable NSString *)tableName {
    NSString *name = NSStringFromClass(self);
    if ([name hasSuffix:@"Model"]) {
        name = [name substringToIndex:(name.length - @"Model".length)];
    }
    if ([name matchesPattern:@"\\w+$"]) {
        ALStringInflector *inflactor = [[NSCache sharedCache] objectForKey:@"ALStringInflector"
                                                              defaultValue:[[ALStringInflector alloc] init]
                                                         cacheDefaultValue:YES];
        return [[inflactor pluralize:[inflactor singularize:name]] stringByConvertingCamelCaseToUnderscore];
    }
    return [[name stringByConvertingCamelCaseToUnderscore] stringByAppendingString:@"_list"];
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

+ (BOOL)withoutRowId {
    return NO;
}


@end

/**
 * @see https://www.sqlite.org/datatype3.html
 */
static AL_FORCE_INLINE NSString * suggestedSqliteDataType(YYClassPropertyInfo *property) {
    
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


static AL_FORCE_INLINE NSData *dataByArchivingObject(id obj) {
    NSData *value = nil;
    if (obj != nil) {
        @try {
            value = [NSKeyedArchiver archivedDataWithRootObject:obj];
        } @catch (NSException *exception) {
            ALLogWarn(@"Exception: %@", exception);
        }
    }
    return value;
}


// the value that saving to DB
static AL_FORCE_INLINE id _Nullable modelColumnValue(ALModel *_Nonnull model, ALDBColumnInfo *_Nonnull colInfo) {
    NSString *propertyName = colInfo.property.name;
    if (unwrapNil(propertyName) == nil ||
        [propertyName isEqualToString:[model.class rowidAliasPropertyName]] ||
        [propertyName isEqualToString:keypath(model.rowid)]) {
        return nil;
    }
    SEL transformer = colInfo.customPropertyToColumnValueTransformer ?: colInfo.property.getter;
    Method method = class_getInstanceMethod(model.class, transformer);
    char *retTypeChar = method_copyReturnType(method);
    YYEncodingType retType = YYEncodingGetType(retTypeChar);
    free(retTypeChar);
    
    switch (retType & YYEncodingTypeMask) {
        case YYEncodingTypeBool: {
            bool num = ((bool (*)(id, SEL))(void *) objc_msgSend)((id) model, transformer);
            return @(num);
        } break;
        case YYEncodingTypeInt8:
        case YYEncodingTypeUInt8: {
            uint8_t num = ((bool (*)(id, SEL))(void *) objc_msgSend)((id) model, transformer);
            return @(num);
        } break;
        case YYEncodingTypeInt16:
        case YYEncodingTypeUInt16: {
            uint16_t num = ((uint16_t(*)(id, SEL))(void *) objc_msgSend)((id) model, transformer);
            return @(num);
        } break;
        case YYEncodingTypeInt32:
        case YYEncodingTypeUInt32: {
            uint32_t num = ((uint32_t(*)(id, SEL))(void *) objc_msgSend)((id) model, transformer);
            return @(num);
        } break;
        case YYEncodingTypeInt64:
        case YYEncodingTypeUInt64: {
            uint64_t num = ((uint64_t(*)(id, SEL))(void *) objc_msgSend)((id) model, transformer);
            return @(num);
        } break;
        case YYEncodingTypeFloat: {
            float num = ((float (*)(id, SEL))(void *) objc_msgSend)((id) model, transformer);
            return @(num);
        } break;
        case YYEncodingTypeDouble: {
            double num = ((double (*)(id, SEL))(void *) objc_msgSend)((id) model, transformer);
            return @(num);
        } break;
        case YYEncodingTypeLongDouble: {
            long double num = ((long double (*)(id, SEL))(void *) objc_msgSend)((id) model, transformer);
            return @((double) num);
        } break;
            
        case YYEncodingTypeObject: {
            id value = ((id(*)(id, SEL))(void *) objc_msgSend)((id) model, transformer);
            // if value isKindOf NSString, NSNumber, NSData, do not need transform
            if ([value isKindOfClass:[NSURL class]]) {
                value = [((NSURL *)value) absoluteString];
            }
            else if (![value isAcceptableSQLArgClassType]) {
                value = dataByArchivingObject(value);
            }
            return value;
        } break;
            
        case YYEncodingTypeClass:
        case YYEncodingTypeBlock: {
            id value = ((id(*)(id, SEL))(void *) objc_msgSend)((id) model, transformer);
            return dataByArchivingObject(value);
        } break;
        case YYEncodingTypeSEL:
        case YYEncodingTypePointer:
        case YYEncodingTypeCString: {
            size_t value = ((size_t(*)(id, SEL))(void *) objc_msgSend)((id) model, transformer);
            return dataByArchivingObject([NSValue valueWithPointer:*((SEL *) value)]);
        } break;
        case YYEncodingTypeStruct:
        case YYEncodingTypeUnion: {
            @try {
                NSValue *value = [model valueForKey:NSStringFromSelector(transformer)];
                return dataByArchivingObject(value);
            } @catch (NSException *exception) {
                ALLogWarn(@"%@", exception);
            }
        } break;
            
        default:
            ALLogWarn(@"Not supported transformer: %@ for property:%@", NSStringFromSelector(transformer),
                      colInfo.property.name);
            break;
    }
    return nil;
}



static AL_FORCE_INLINE void setModelPropertyValueFromResultSet(FMResultSet    *rs,
                                                            int             columnIndex,
                                                            ALModel        *model,
                                                            ALDBColumnInfo *colinfo) {
    YYClassPropertyInfo *property = colinfo.property;
    SEL transformer = colinfo.customPropertyFromColumnValueTransformer;
    if (transformer != nil) {
        // customTransform{PropertyName}FromRecord:columnIndex:
        ((void (*)(id, SEL, id, int))(void *) objc_msgSend)((id) model, transformer, (id) rs, columnIndex);
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
                
                if ([property.cls isSubclassOfClass:[NSMutableString class]]) {
                    value = [value mutableCopy];
                }
                
            } else if ([property.cls isSubclassOfClass:[NSURL class]]) {
                value = [NSURL URLWithString:[rs stringForColumnIndex:columnIndex]];
                
            } else if ([property.cls isSubclassOfClass:[NSNumber class]]) {
                int columnType = sqlite3_column_type([rs.statement statement], columnIndex);
                if (columnType == SQLITE_INTEGER) {
                    value = @([rs longLongIntForColumnIndex:columnIndex]);
                } else {
                    value = @([rs doubleForColumnIndex:columnIndex]);
                }
                
            } else if ([property.cls isSubclassOfClass:[NSData class]]) {
                value = [rs dataForColumnIndex:columnIndex];
                
                if ([property.cls isSubclassOfClass:[NSMutableData class]]) {
                    value = [value mutableCopy];
                }
                
            } else if ([property.cls isSubclassOfClass:[NSDate class]]) {
                value = [rs dateForColumnIndex:columnIndex];
                
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
                
                if (value != nil) {
                    if ([property.cls isSubclassOfClass:[NSMutableArray class]] ||
                        [property.cls isSubclassOfClass:[NSMutableDictionary class]] ||
                        [property.cls isSubclassOfClass:[NSMutableSet class]]) {
                        value = [value mutableCopy];
                    }
                }
            }
            
            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id) model, setter, value);
        } break;
    }
}

static AL_FORCE_INLINE NSDictionary<NSString * /*colname*/, NSArray<ALDBColumnInfo *> *> *modelColumnPropertyMapper(
    FMResultSet *rs, Class modelClass) {
    
    NSMutableSet *resultColumnNames = [NSMutableSet setWithCapacity:rs.columnCount];
    for (int idx = 0; idx < rs.columnCount; ++idx) {
        [resultColumnNames addObject:[rs columnNameForIndex:idx]];
    }
    // properties and columns are many to many mappings, not one to one.
    NSMutableDictionary<NSString *, NSArray<ALDBColumnInfo *> *> *columnPropertyMapper =
        [NSMutableDictionary dictionary];
    [[modelClass tableColumns] bk_each:^(NSString *propertyName, ALDBColumnInfo *colInfo) {
        NSString *mappedColName = [modelClass mappedColumnNameForProperty:propertyName];
        if (![resultColumnNames containsObject:mappedColName]) {
            return;
        }

        NSMutableArray *propertyColumnInfos = (NSMutableArray *) columnPropertyMapper[mappedColName];
        if ([propertyColumnInfos isKindOfClass:NSMutableArray.class]) {
            [propertyColumnInfos addObject:colInfo];
        } else {
#if DEBUG
            assert(propertyColumnInfos == nil);
#endif
            columnPropertyMapper[mappedColName] = [NSMutableArray arrayWithObject:colInfo];
        }
    }];

    return columnPropertyMapper;
}

static AL_FORCE_INLINE void setModelPropertyValueWithResultSet(FMResultSet *rs, ALModel *oneModel,
                                                            NSDictionary * columnPropertyMapper) {
    [oneModel markModelFromDB:YES];
    [columnPropertyMapper bk_each:^(NSString *colName, NSArray<ALDBColumnInfo *> *objs) {
        if ([colName.lowercaseString isEqualToString:kRowIdColumnName]) {
            [oneModel setRowid:[rs longForColumn:colName]];
            return;
        }
        int idx = [rs columnIndexForName:colName];
        [objs bk_each:^(ALDBColumnInfo *obj) {
            setModelPropertyValueFromResultSet(rs, idx, oneModel, obj);
        }];
    }];
}


static AL_FORCE_INLINE NSArray<__kindof ALModel *> *_Nullable modelsFromResultSet(FMResultSet *rs, Class modelClass) {
    if (rs == nil || ![modelClass isSubclassOfClass:[ALModel class]] || rs.columnCount == 0) {
        [rs close];
        return nil;
    }
    
    NSDictionary<NSString * /*colname*/, NSArray<ALDBColumnInfo *> *> *columnPropertyMapper
        = modelColumnPropertyMapper(rs, modelClass);
    
    NSMutableArray *models = [NSMutableArray array];
    while ([rs next]) {
        ALModel *oneModel = [[modelClass alloc] init];
        setModelPropertyValueWithResultSet(rs, oneModel, columnPropertyMapper);
        [models addObject:oneModel];
    }
    [rs close];
    
    return [models copy];
}
