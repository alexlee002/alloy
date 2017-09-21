//
//  NSObject+AL_ActiveRecord.m
//  patchwork
//
//  Created by Alex Lee on 27/06/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "NSObject+AL_ActiveRecord.h"
#import "__ALResultSetEnumerator.h"
#import "__ALModelMeta+ActiveRecord.h"
#import "__ALModelHelper.h"
#import "ALDatabase+Statement.h"
#import "__ALDatabase+private.h"
#import "ALSQLStatement+Database.h"
#import "YYClassInfo.h"
#import "ALActiveRecord.h"
#import "__ALPropertyColumnBindings+private.h"
#import "ALDatabase+CoreDB.h"
#import "ALSQLSelect.h"
#import "ALSQLInsert.h"
#import "ALSQLUpdate.h"
#import "ALSQLDelete.h"
#import "ALUtilitiesHeader.h"
#import "NSString+ALHelper.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <BlocksKit.h>

// the value that saving to DB
static id _Nullable columnValueFromModel(id<NSObject> _Nonnull model, ALPropertyColumnBindings *_Nonnull binding);

#define __AL_VERIFY_DB_OR_RETURN(ret)                                         \
    if ([self al_database] == nil) {                                          \
        ALLogWarn(@"model \"%@\" doesn't bind to any database!", self.class); \
        return (ret);                                                         \
    }

@implementation NSObject (AL_ActiveRecord)

- (ALDBRowIdType)al_rowid {
    return [objc_getAssociatedObject(self, @selector(al_rowid)) integerValue];
}

- (void)al_setRowid:(ALDBRowIdType)rowid {
    objc_setAssociatedObject(self, @selector(al_rowid), @(rowid), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)al_autoIncrement {
    id val = objc_getAssociatedObject(self, @selector(al_autoIncrement));
    if ([val isKindOfClass:NSNumber.class]) {
        return [val boolValue];
    }
    return YES; // default value is YES
}

- (void)al_setAutoIncrement:(BOOL)autoIncrement {
    objc_setAssociatedObject(self, @selector(al_autoIncrement), @(autoIncrement), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - utils
+ (nullable ALDatabase *)al_database {
    static NSString *const selName = NSStringFromSelector(@selector(databaseIdentifier));
    
    Class metacls = objc_getMetaClass(object_getClassName(self));
    NSDictionary *classMethods = [YYClassInfo classInfoWithClass:metacls].methodInfos;
    if (classMethods[selName] == nil) {
        return nil;
    }
    NSString *path = [(id<ALActiveRecord>)self databaseIdentifier];
    if (path == nil) {
        return nil;
    }
    return [ALDatabase databaseWithPath:path keepAlive:YES];
}

- (nullable ALDatabase *)al_database {
    return [self.class al_database];
}

+ (const ALDBColumnProperty &)al_rowidColumn {
    static const ALDBColumnProperty property([ALPropertyColumnBindings
        bindingWithModelMeta:[_ALModelMeta metaWithClass:self]
                propertyMeta:[_ALModelMeta metaWithClass:self]
                                 ->_allPropertyMetasDict[al_keypathForClass(NSObject, al_rowid)]
                      column:@(ALDBColumn::s_rowid.to_string().c_str())]);
    return property;
}

+ (const std::list<const ALDBColumnProperty> &)al_allColumnProperties {
    _ALModelTableBindings *tableBindings = [_ALModelTableBindings bindingsWithClass:self];
    return tableBindings->_allColumnProperties;
}

+ (const ALDBColumnProperty)al_columnPropertyForProperty:(NSString *)propertyName {
    if ([propertyName isEqualToString:al_keypathForClass(NSObject, al_rowid)]) {
        return [self al_rowidColumn];
    }
    
    _ALModelTableBindings *tableBindings = [_ALModelTableBindings bindingsWithClass:self];
    NSString *colName = al_stringOrEmpty([tableBindings columnNameForProperty:propertyName]);
    ALPropertyColumnBindings *colbinding = tableBindings->_columnsDict[colName];
    if (colbinding) {
        return ALDBColumnProperty(colbinding);
    }
    return ALDBColumnProperty();
}

+ (nullable NSString *)al_columnNameForPropertyNamed:(NSString *)propertyName {
    return [[_ALModelTableBindings bindingsWithClass:self] columnNameForProperty:propertyName];
}

#pragma mark - transaction
+ (void)al_inTransaction:(void (^)(BOOL *rollback))transaction {
    if (![self al_database]) {
        return;
    }
    [[self al_database] inTransaction:transaction eventHandler:nil];
}

- (void)al_inTransaction:(void (^)(BOOL *rollback))transaction {
    [self.class al_inTransaction:transaction];
}

#pragma mark - select
+ (nullable NSArray<id<ALActiveRecord>> *)al_modelsWithCondition:(const ALDBCondition &)condition {
    NSMutableArray *objects = [NSMutableArray array];
    for (id obj in [self al_modelEnumeratorWithCondition:condition]) {
        if (obj != nil) {
            [objects addObject: obj];
        }
    }
    return objects;
}

+ (NSInteger)al_modelsCountWithCondition:(const ALDBCondition &)condition {
    ALSQLSelect *stmt =
        [[[[ALSQLSelect statement] select:{ ALDBColumnProperty(ALDBColumn::s_any, nil).count() } distinct:NO]
            from:[(id<ALActiveRecord>) self tableName]] where:condition];
    
    ALDBResultSet *rs = [[self al_database] select:stmt];
    if ([rs next]) {
        return [rs integerValueForColumnIndex:0];
    }
    return 0;
}

+ (nullable NSEnumerator *)al_modelEnumeratorWithCondition:(const ALDBCondition &)condition {
    const ALDBResultColumnList resultColumns = [self al_allColumnProperties];

    ALSQLSelect *stmt = [[[[ALSQLSelect statement] select:resultColumns distinct:NO]
        from:[(id<ALActiveRecord>) self tableName]] where:condition];

    ALDBResultSet *rs = [[self al_database] select:stmt];
    if (rs == nil) {
        return nil;
    }
    return [__ALResultSetEnumerator enumatorWithResultSet:rs modelClass:self resultColumns:resultColumns];
}

+ (nullable id<ALActiveRecord>)al_modelWithRowId:(ALDBRowIdType)rowId {
    for (id<ALActiveRecord> model in [self al_modelEnumeratorWithCondition:self.al_rowidColumn==rowId]) {
        if (model) {
            return model;
        }
    }
    return nil;
}

+ (id<ALARFetcher>)al_modelFetcher {
    if (![self al_database]) {
        return nil;
    }
    return [[[ALSQLSelect statementWithDatabase:[self al_database]] select:[self al_allColumnProperties] distinct:NO]
        from:[(id<ALActiveRecord>) self tableName]];
}

#pragma mark - insert

- (NSDictionary<NSString */* columnName */, id> *)al_modelValuesToSave {
    const std::list<const ALDBColumnProperty> allColumns = [self.class al_allColumnProperties];
    NSMutableDictionary<NSString *, id> *valuesDict = [NSMutableDictionary dictionaryWithCapacity:allColumns.size()];
    for (auto c : allColumns) {
        if (ALDBColumn::s_rowid == c) {
            continue;
        }
        valuesDict[@(c.name().c_str())] = al_wrapNil(columnValueFromModel(self, c.column_binding()));
    }
    return valuesDict;
}

+ (NSArray<NSString * /*columnName*/> *)al_primaryColumns {
    _ALModelTableBindings *tableBinding = [_ALModelTableBindings bindingsWithClass:self];
    if (tableBinding == nil) { return nil; }
    
    return [tableBinding->_allPrimaryKeys bk_map:^NSString *(NSString *pn) {
        return [tableBinding columnNameForProperty:pn];
    }];
}

- (const ALDBCondition)al_defaultModelUpdateCondition {
    if (!al_safeInvokeSelector(BOOL, self.class, @selector(withoutRowId))) {
#if DEBUG
        if (self.al_rowid == 0) {
            ALLogWarn(@"'rowid' is not specified. Or you can specify a condition insted.");
        }
#endif
        return [self.class al_rowidColumn] == self.al_rowid;
    } else {
        NSArray *primaryColumns = [self.class al_primaryColumns];
        al_guard_or_return1(primaryColumns.count > 0, nullptr, @"no primary key defined for model: %@", self.class);
        _ALModelTableBindings *tableBindings = [_ALModelTableBindings bindingsWithClass:self.class];

        ALSQLExpr condition;
        for (NSString *cn in primaryColumns) {
            condition = condition && (ALDBColumn(cn) == columnValueFromModel(self, tableBindings->_columnsDict[cn]));
        }
        return condition;
    }
}

- (BOOL)al_saveOrReplace:(BOOL)replaceOnConflict {
    return [self.class al_saveModels:@[(id<ALActiveRecord>)self] replace:replaceOnConflict];
}

+ (BOOL)al_saveModels:(NSArray<id<ALActiveRecord>> *)models replace:(BOOL)replaceOnConflict {
    const std::list<const ALDBColumnProperty> allColumns = [self.class al_allColumnProperties];
    
    ALSQLClause clause = [[[ALSQLInsert statement]
                           insertInto:[(id<ALActiveRecord>) self tableName]
                           columns:ALDBColumnList(allColumns)
                           onConflict:replaceOnConflict ? ALDBConflictPolicyReplace : ALDBConflictPolicyDefault] SQLClause];
    
    return [[self al_database] inTransaction:^(BOOL *rollback){
        auto coreDB = [[self al_database] _coreDB];
        if (!coreDB) {
            ALLogError(@"database is nil! model:\"%@\"", self);
            return;
        }
        aldb::RecyclableStatement stmt = coreDB->prepare(clause.sql_str());
        if (!stmt) {
            ALDB_LOG_ERROR(coreDB);
            if (rollback) {*rollback = YES;}
            return;
        }
        
        [models bk_each:^(id model) {
#if DEBUG
            if ([model class] != self) {
                ALLogWarn(@"Unexpected model class: %@, should be: %@", [model class], self);
            }
#endif
            stmt->reset_bindings();
            int idx = 1;
            BOOL autoIncrementFlag = NO;
            for (auto c : allColumns) {
                if (!autoIncrementFlag && [self isAutoIncrementColumn:c] && [model al_autoIncrement]) {
                    autoIncrementFlag = YES;
                    stmt->bind_value(aldb::SQLValue(nullptr), idx);
                } else {
                    auto value(aldb::SQLValue(ALSQLValue(columnValueFromModel(model, c.column_binding()))));
                    stmt->bind_value(value, idx);
                }
                ++idx;
            }
            
            stmt->step();
            if (stmt->has_error()) {
                ALLogError(@"%s", std::string(*(stmt->get_error())).c_str());
            } else {
                ((NSObject *)model).al_rowid = stmt->last_insert_rowid();
            }
        }];
    } eventHandler:nil];
}

+ (BOOL)isAutoIncrementColumn:(const ALDBColumnProperty &)cp {
    ALPropertyColumnBindings *colbinding = cp.column_binding();
    if (colbinding == nil || cp.binding_class() == Nil) {
        return NO;
    }
    _ALModelTableBindings *tableBindings = [_ALModelTableBindings bindingsWithClass:cp.binding_class()];
    return [tableBindings->_allPrimaryKeys isEqualToArray:@[ [colbinding propertyName] ]] &&
           (colbinding.columnDefine.column_type() == ALDBColumnTypeInt ||
            colbinding.columnDefine.column_type() == ALDBColumnTypeLong);
}

- (BOOL)al_updateOrReplace:(BOOL)replaceOnConflict {
    return [[self.class al_database]
        execute:[[[[ALSQLUpdate statement]
                        update:[self.class tableName]
                    onConflict:replaceOnConflict ? ALDBConflictPolicyReplace : ALDBConflictPolicyDefault]
                    setValuesWithDictionary:[self al_modelValuesToSave]]
                    where:[self al_defaultModelUpdateCondition]]];
}

+ (BOOL)al_updateModels:(NSArray<id<ALActiveRecord>> *)models replace:(BOOL)replaceOnConflict {
    if (models.count == 0) {
        return YES;
    }

    auto updateColumns = [self al_allColumnProperties];
    std::list<const ALDBColumnProperty> allColumns(updateColumns);

    ALDBCondition cond;
    _ALModelTableBindings *tableBindings = [_ALModelTableBindings bindingsWithClass:self];
    for (NSString *pn in tableBindings->_allPrimaryKeys) {
        NSString *cn = [tableBindings columnNameForProperty:pn];
        allColumns.push_back(ALDBColumnProperty(tableBindings->_columnsDict[cn]));
        cond = cond && (ALSQLExpr(ALDBColumn(cn)) == ALSQLExpr::s_param_mark);
    }
    ALDBConflictPolicy policy = replaceOnConflict ? ALDBConflictPolicyReplace : ALDBConflictPolicyDefault;

    ALSQLClause clause = [[[[[ALSQLUpdate statement] update:[(id<ALActiveRecord>) self tableName] onConflict:policy]
        columns:ALDBColumnList(updateColumns)] where:cond] SQLClause];

    return [[self al_database] inTransaction:^(BOOL *rollback) {
        aldb::RecyclableStatement stmt = [[self al_database] _coreDB]->prepare(clause.sql_str());
        if (!stmt) {
            if (rollback) {
                *rollback = YES;
            }
            return;
        }
        [models bk_each:^(id<ALActiveRecord> model) {
            stmt->reset_bindings();

            int idx = 1;
            for (auto c : allColumns) {
                auto value(aldb::SQLValue(ALSQLValue(columnValueFromModel(model, c.column_binding()))));
                stmt->bind_value(value, idx);
                ++idx;
            }

            stmt->step();
            if (stmt->has_error()) {
                ALLogError(@"%s", std::string(*(stmt->get_error())).c_str());
            }
        }];
    }
                                eventHandler:nil];

    return NO;
}

- (BOOL)al_updateProperties:(NSArray<NSString *> *)propertiesNames replace:(BOOL)replaceOnConflict {
    NSMutableDictionary *valuesDict = [NSMutableDictionary dictionaryWithCapacity:propertiesNames.count];

    _ALModelTableBindings *tableBindings = [_ALModelTableBindings bindingsWithClass:self.class];
    [propertiesNames bk_each:^(NSString *pn) {
        ALPropertyColumnBindings *binding = tableBindings->_columnsDict[[tableBindings columnNameForProperty:pn]];
        if (binding) {
            valuesDict[[binding columnName]] = al_wrapNil(columnValueFromModel(self, binding));
        }
    }];

    return [[self.class al_database]
        execute:[[[[ALSQLUpdate statement]
                        update:[self.class tableName]
                    onConflict:replaceOnConflict ? ALDBConflictPolicyReplace : ALDBConflictPolicyDefault]
                    setValuesWithDictionary:valuesDict] where:[self al_defaultModelUpdateCondition]]];
}

+ (BOOL)al_updateProperties:(NSDictionary<NSString */* propertyName */, id> *)propertyValues
              withCondition:(const ALDBCondition &)condition
                    replace:(BOOL)replaceOnConflict {
    NSMutableDictionary *columnValuesDict = [NSMutableDictionary dictionaryWithCapacity:propertyValues.count];

    _ALModelTableBindings *tableBindings = [_ALModelTableBindings bindingsWithClass:self];
    [propertyValues bk_each:^(NSString *pn, id obj) {
        columnValuesDict[[tableBindings columnNameForProperty:pn]] = obj;
    }];

    return [[self al_database] execute:[[[[ALSQLUpdate statement] update:[(id<ALActiveRecord>) self tableName]
                                                              onConflict:replaceOnConflict ? ALDBConflictPolicyReplace
                                                                                           : ALDBConflictPolicyDefault]
                                           setValuesWithDictionary:columnValuesDict] where:condition]];
}

#pragma mark - delete
+ (BOOL)al_deleteModelsWithCondition:(const ALDBCondition &)condition {
    return [[self al_database]
        execute:[[[ALSQLDelete statement] deleteFrom:[(id<ALActiveRecord>) self tableName]] where:condition]];
}

- (BOOL)al_deleteModel {
    return [[self.class al_database] execute:[[[ALSQLDelete statement] deleteFrom:[self.class tableName]]
                                              where:[self al_defaultModelUpdateCondition]]];
}

@end

static AL_FORCE_INLINE id _Nullable columnValueFromModel(id<NSObject> _Nonnull model,
                                                         ALPropertyColumnBindings *_Nonnull binding) {
    NSString *propertyName = [binding propertyName];
    if (propertyName == nil) {
        return nil;
    }

    _ALModelPropertyMeta *propertyInfo = binding->_propertyMeta;
    SEL getter = [binding customPropertyValueGetter] ?: propertyInfo->_getter;
    
    switch (propertyInfo->_type & YYEncodingTypeMask) {
        case YYEncodingTypeBool: {
            bool num = ((bool (*)(id, SEL))(void *) objc_msgSend)((id) model, getter);
            return @(num);
        } break;
            
        case YYEncodingTypeInt8: {
            int8_t num = ((int8_t (*)(id, SEL))(void *) objc_msgSend)((id) model, getter);
            return @(num);
        } break;
        case YYEncodingTypeUInt8: {
            uint8_t num = ((uint8_t (*)(id, SEL))(void *) objc_msgSend)((id) model, getter);
            return @(num);
        } break;
            
        case YYEncodingTypeInt16: {
            int16_t num = ((int16_t (*)(id, SEL))(void *) objc_msgSend)((id) model, getter);
            return @(num);
        } break;
        case YYEncodingTypeUInt16: {
            uint16_t num = ((uint16_t(*)(id, SEL))(void *) objc_msgSend)((id) model, getter);
            return @(num);
        } break;
            
        case YYEncodingTypeInt32: {
            int32_t num = ((int32_t (*)(id, SEL))(void *) objc_msgSend)((id) model, getter);
            return @(num);
        } break;
        case YYEncodingTypeUInt32: {
            uint32_t num = ((uint32_t(*)(id, SEL))(void *) objc_msgSend)((id) model, getter);
            return @(num);
        } break;
            
        case YYEncodingTypeInt64: {
            int64_t num = ((int64_t (*)(id, SEL))(void *) objc_msgSend)((id) model, getter);
            return @(num);
        } break;
            
        case YYEncodingTypeUInt64: {
            uint64_t num = ((uint64_t(*)(id, SEL))(void *) objc_msgSend)((id) model, getter);
            return @(num);
        } break;
        case YYEncodingTypeFloat: {
            float num = ((float (*)(id, SEL))(void *) objc_msgSend)((id) model, getter);
            return @(num);
        } break;
        case YYEncodingTypeDouble: {
            double num = ((double (*)(id, SEL))(void *) objc_msgSend)((id) model, getter);
            return @(num);
        } break;
        case YYEncodingTypeLongDouble: {
            long double num = ((long double (*)(id, SEL))(void *) objc_msgSend)((id) model, getter);
#ifdef DEBUG
            if (num != (double) num) {
                ALLogError(@"accuracy lost from (long double) to (double)");
            }
#endif
            return @((double) num);
        } break;
            
        case YYEncodingTypeObject: {
            id value = ((id(*)(id, SEL))(void *) objc_msgSend)((id) model, getter);
            return value;
        } break;
            
        case YYEncodingTypeClass:
        case YYEncodingTypeBlock: {
            id value = ((id(*)(id, SEL))(void *) objc_msgSend)((id) model, getter);
            return value;
        } break;
        case YYEncodingTypeSEL:
        case YYEncodingTypePointer:
        case YYEncodingTypeCString: {
            size_t value = ((size_t(*)(id, SEL))(void *) objc_msgSend)((id) model, getter);
            return [NSValue valueWithPointer:*((SEL *) value)];
        } break;
        case YYEncodingTypeStruct:
        case YYEncodingTypeUnion: {
            @try {
                NSValue *value = [(id)model valueForKey:NSStringFromSelector(getter)];
                return value;
            } @catch (NSException *exception) {
                ALLogWarn(@"%@", exception);
            }
        } break;
            
        default:
            ALLogWarn(@"Getter: \"%@\" not found for property:\"%@\"", NSStringFromSelector(getter),
                      propertyInfo->_name);
            break;
    }
    return nil;
}
