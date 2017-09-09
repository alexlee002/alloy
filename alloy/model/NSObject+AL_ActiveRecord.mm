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
static AL_FORCE_INLINE id _Nullable columnValueFromModel(id<NSObject> _Nonnull model, ALPropertyColumnBindings *_Nonnull binding) {
    NSString *propertyName = [binding propertyName];
    if (propertyName == nil /*||
        [propertyName isEqualToString:[model.class rowidAliasPropertyName]] ||
        [propertyName isEqualToString:al_keypath(model.rowid)]*/) {
        return nil;
    }
    
    _ALModelPropertyMeta *propertyInfo = binding->_propertyMeta;
    SEL transformer = [binding customPropertyValueToColumnTransformer] ?: propertyInfo->_getter;

    switch (propertyInfo->_type & YYEncodingTypeMask) {
        case YYEncodingTypeBool: {
            bool num = ((bool (*)(id, SEL))(void *) objc_msgSend)((id) model, transformer);
            return @(num);
        } break;
            
        case YYEncodingTypeInt8: {
            int8_t num = ((int8_t (*)(id, SEL))(void *) objc_msgSend)((id) model, transformer);
            return @(num);
        } break;
        case YYEncodingTypeUInt8: {
            uint8_t num = ((uint8_t (*)(id, SEL))(void *) objc_msgSend)((id) model, transformer);
            return @(num);
        } break;
            
        case YYEncodingTypeInt16: {
            int16_t num = ((int16_t (*)(id, SEL))(void *) objc_msgSend)((id) model, transformer);
            return @(num);
        } break;
        case YYEncodingTypeUInt16: {
            uint16_t num = ((uint16_t(*)(id, SEL))(void *) objc_msgSend)((id) model, transformer);
            return @(num);
        } break;
            
        case YYEncodingTypeInt32: {
            int32_t num = ((int32_t (*)(id, SEL))(void *) objc_msgSend)((id) model, transformer);
            return @(num);
        } break;
        case YYEncodingTypeUInt32: {
            uint32_t num = ((uint32_t(*)(id, SEL))(void *) objc_msgSend)((id) model, transformer);
            return @(num);
        } break;
            
        case YYEncodingTypeInt64: {
            int64_t num = ((int64_t (*)(id, SEL))(void *) objc_msgSend)((id) model, transformer);
            return @(num);
        } break;
        
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
#ifdef DEBUG
            if (num != (double) num) {
                ALLogError(@"accuracy lost from (long double) to (double)");
            }
#endif
            return @((double) num);
        } break;
            
        case YYEncodingTypeObject: {
            id value = ((id(*)(id, SEL))(void *) objc_msgSend)((id) model, transformer);
            return value;
        } break;
            
        case YYEncodingTypeClass:
        case YYEncodingTypeBlock: {
            id value = ((id(*)(id, SEL))(void *) objc_msgSend)((id) model, transformer);
            return value;
        } break;
        case YYEncodingTypeSEL:
        case YYEncodingTypePointer:
        case YYEncodingTypeCString: {
            size_t value = ((size_t(*)(id, SEL))(void *) objc_msgSend)((id) model, transformer);
            return [NSValue valueWithPointer:*((SEL *) value)];
        } break;
        case YYEncodingTypeStruct:
        case YYEncodingTypeUnion: {
            @try {
                NSValue *value = [(id)model valueForKey:NSStringFromSelector(transformer)];
                return value;
            } @catch (NSException *exception) {
                ALLogWarn(@"%@", exception);
            }
        } break;
            
        default:
            ALLogWarn(@"Not supported transformer: %@ for property:%@", NSStringFromSelector(transformer),
                      propertyInfo->_name);
            break;
    }
    return nil;
}


@implementation NSObject (AL_ActiveRecord)

- (ALDBRowIdType)al_rowid {
    return [objc_getAssociatedObject(self, @selector(al_rowid)) integerValue];
}

- (void)al_setRowid:(ALDBRowIdType)al_rowid {
    objc_setAssociatedObject(self, @selector(al_rowid), @(al_rowid), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (const ALDBColumnProperty &)al_rowidColumn {
    static const ALDBColumnProperty property([ALPropertyColumnBindings
        bindingWithModel:self
            propertyMeta:[_ALModelMeta metaWithClass:self]
                             ->_allPropertyMetasDict[al_keypathForClass(NSObject, al_rowid)]
                  column:@(ALDBColumn::s_rowid.to_string().c_str())]);
    return property;

    //    static std::shared_ptr<ALDBColumnProperty> property = nullptr;
    //    if (!property) {
//            _ALModelMeta *modelMeta = [_ALModelMeta metaWithClass:self];
//            NSString *rowid = al_keypathForClass(NSObject, al_rowid);
//            ALPropertyColumnBindings *binding =
//                [ALPropertyColumnBindings bindingWithPropertyMeta:modelMeta->_allPropertyMetasDict[rowid]
//                column:rowid];
    //        property = std::shared_ptr<ALDBColumnProperty>(new ALDBColumnProperty(ALDBColumn::s_rowid, binding));
    //    }
    //    return *property;
}

// not include rowid
+ (const std::list<const ALDBColumnProperty> &)al_allColumnProperties {
    _ALModelTableBindings *tableBindings = [_ALModelTableBindings bindingsWithClass:self];
    return tableBindings->_allColumnProperties;
}

+ (const ALDBColumnProperty)al_columnPropertiesForProperty:(NSString *)propertyName {
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


+ (nullable ALDatabase *)al_database {
    static NSString *const selName = NSStringFromSelector(@selector(databaseIdentifier));
    NSDictionary *methods = [YYClassInfo classInfoWithClass:self].classMethodInfos;
    if (methods[selName] == nil) {
        return nil;
    }
    NSString *path = [(id<ALActiveRecord>)self databaseIdentifier];
    if (path == nil) {
        return nil;
    }
    return [ALDatabase databaseWithPath:path keepAlive:YES];
}

+ (nullable NSArray<id<ALActiveRecord>> *)al_modelsWithCondition:(const ALDBCondition &)condition {
    NSMutableArray *objects = [NSMutableArray array];
    for (id obj in [self al_modelEnumeratorWithCondition:condition]) {
        if (obj != nil) {
            [objects addObject: obj];
        }
    }
    return objects;
}

+ (nullable NSEnumerator<id<ALActiveRecord>> *)al_modelEnumeratorWithCondition:(const ALDBCondition &)condition {
    const std::list<const ALDBResultColumn> resultColumns = {ALDBResultColumn([self al_rowidColumn]),
                                                             ALDBResultColumn(ALDBColumn::s_any)};

    ALSQLSelect *stmt = [[[[ALSQLSelect statement] select:resultColumns distinct:NO]
        from:[(id<ALActiveRecord>) self tableName]] where:condition];

    ALDBResultSet *rs = [[self al_database] select:stmt];
    return [__ALResultSetEnumerator enumatorWithResultSet:rs modelClass:self resultColumns:resultColumns];
}

+ (nullable NSString *)al_columnNameForPropertyNamed:(NSString *)propertyName {
    return [[_ALModelTableBindings bindingsWithClass:self] columnNameForProperty:propertyName];
}


+ (nullable id<ALActiveRecord>)al_modelWithRowId:(ALDBRowIdType)rowId {
    for (id<ALActiveRecord> model in [self al_modelEnumeratorWithCondition:self.al_rowidColumn==rowId]) {
        if (model) {
            return model;
        }
    }
    return nil;
}

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

- (const ALDBCondition)al_defaultModelUpdateCondition {
    if (!al_safeInvokeSelector(BOOL, self.class, @selector(withoutRowId))) {
        al_guard_or_return1(self.al_rowid != 0, nullptr,
                            @"'rowid' is not specified. Or you can specify a condition insted.");
        
        return [self.class al_rowidColumn] == self.al_rowid;
    } else {
        _ALModelTableBindings *tableBindings = [_ALModelTableBindings bindingsWithClass:self.class];
        NSArray<NSString *> *primaryKeys = tableBindings->_allPrimaryKeys;
        if (primaryKeys.count == 0) {
            return nullptr;
        }
        
        ALSQLExpr condition;
        for (NSString *pn in primaryKeys) {
            if (!condition.is_empty()) {
                condition.append(" AND ");
            }
            
            NSString *cn = [tableBindings columnNameForProperty:pn];
            condition.append(cn);
            condition.append(" = ?", {columnValueFromModel(self, tableBindings->_columnsDict[cn])});
        }
        return (condition);
    }
}

- (BOOL)al_saveOrReplace:(BOOL)replaceOnConflict {
    return [[self.class al_database]
        execute:[[[ALSQLInsert statement]
                    insertInto:[self.class tableName]
                    onConflict:replaceOnConflict ? ALDBConflictPolicyReplace : ALDBConflictPolicyDefault]
                    valuesWithDictionary:[self al_modelValuesToSave]]];
}

- (BOOL)al_updateOrReplace:(BOOL)replaceOnConflict {
    return [[self.class al_database]
        execute:[[[[ALSQLUpdate statement]
                        update:[self.class tableName]
                    onConflict:replaceOnConflict ? ALDBConflictPolicyReplace : ALDBConflictPolicyDefault]
                    setValuesWithDictionary:[self al_modelValuesToSave]]
                    where:[self al_defaultModelUpdateCondition]]];
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
                    setValuesWithDictionary:valuesDict]
                    where:[self al_defaultModelUpdateCondition]]];
}

- (BOOL)al_deleteModel {
    return [[self.class al_database] execute:[[[ALSQLDelete statement] deleteFrom:[self.class tableName]]
                                                 where:[self al_defaultModelUpdateCondition]]];
}

+ (BOOL)al_saveModels:(NSArray<id<ALActiveRecord>> *)models replace:(BOOL)replaceOnConflict {
    const std::list<const ALDBColumnProperty> allColumns = [self.class al_allColumnProperties];

    ALSQLClause clause = [[[ALSQLInsert statement]
        insertInto:[(id<ALActiveRecord>) self tableName]
           columns:ALDBColumnList(allColumns)
        onConflict:replaceOnConflict ? ALDBConflictPolicyReplace : ALDBConflictPolicyDefault] SQLClause];

    aldb::RecyclableStatement stmt = [[self al_database] _coreDB]->prepare(clause.sql_str());
    if (!stmt) {
        return NO;
    }

    return [[self al_database] inTransaction:^(BOOL *rollback){
        [models bk_each:^(id<ALActiveRecord> model) {
            stmt->reset_bindings();
            int idx = 1;
            for (auto c : allColumns) {
                stmt->bind_value(columnValueFromModel(model, c.column_binding()), idx);
                ++idx;
            }
            stmt->step();
            if (stmt->has_error()) {
                ALLogError(@"%s", std::string(*(stmt->get_error())).c_str());
            } else {
                if (replaceOnConflict) {
                    ((NSObject *)model).al_rowid = stmt->last_insert_rowid();
                }
            }
        }];
    } eventHandler:nil];
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

+ (BOOL)al_updateModels:(NSArray<id<ALActiveRecord>> *)models replace:(BOOL)replaceOnConflict {
    if (models.count == 0) {
        return YES;
    }
    
    const std::list<const ALDBColumnProperty> columns = [self al_allColumnProperties];
    const ALDBCondition cond = [(id) models.firstObject al_defaultModelUpdateCondition];
    std::list<const ALDBColumnProperty> allColumns(columns);
    allColumns.insert(allColumns.end(), cond.sqlArgs().size(), ALDBColumnProperty(ALDBColumn("?"), nil));
    
    ALDBConflictPolicy policy = replaceOnConflict ? ALDBConflictPolicyReplace : ALDBConflictPolicyDefault;

    ALSQLClause clause = [[[[[ALSQLUpdate statement] update:[(id<ALActiveRecord>) self tableName] onConflict:policy]
        columns:ALDBColumnList(columns)] where:cond] SQLClause];

    aldb::RecyclableStatement stmt = [[self al_database] _coreDB]->prepare(clause.sql_str());
    if (!stmt) {
        return NO;
    }
    
    return [[self al_database] inTransaction:^(BOOL *rollback){
        [models bk_each:^(id<ALActiveRecord> model) {
            stmt->reset_bindings();
            
            int idx = 1;
            for (auto c : allColumns) {
                stmt->bind_value(columnValueFromModel(model, c.column_binding()), idx);
                ++idx;
            }
           
            stmt->step();
            if (stmt->has_error()) {
                ALLogError(@"%s", std::string(*(stmt->get_error())).c_str());
            }
        }];
    } eventHandler:nil];

    return NO;
}

+ (BOOL)al_deleteModelsWithCondition:(const ALDBCondition &)condition {
    return [[self al_database]
        execute:[[[ALSQLDelete statement] deleteFrom:[(id<ALActiveRecord>) self tableName]] where:condition]];
}

@end
