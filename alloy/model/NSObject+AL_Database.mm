//
//  NSObject+AL_Database.m
//  alloy
//
//  Created by Alex Lee on 09/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "NSObject+AL_Database.h"
#import "ALActiveRecord.h"
#import "ALLock.h"
#import "NSString+ALHelper.h"
#import "ALLogger.h"
#import "ALDBExpr.h"
#import "ALModelSelect.h"
#import "ALModelUpdate.h"
#import "ALModelDelete.h"
#import "ALModelInsert.h"
#import "ALDBResultColumn.h"
#import "ALDBTypeDefines.h"
#import "_ALModelHelper+cxx.h"
#import "NSObject+SQLValue.h"
#import "ALStringInflector.h"
#import "ALDBTableBinding_Private.h"
#import <objc/runtime.h>
#import <objc/message.h>

NSString *ALTableNameForModel(__unsafe_unretained Class cls) {
    static NSMutableDictionary<NSString *, NSString *> *CacheDict = nil;
    const char *cls_name = class_getName(cls);
    NSString *className  = @(cls_name);
    
    static dispatch_semaphore_t dsem;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CacheDict = [NSMutableDictionary dictionary];
        dsem      = dispatch_semaphore_create(1);
    });
    
    __block NSString *tableName = CacheDict[className];
    if (tableName == nil) {
        with_gcd_semaphore(dsem, DISPATCH_TIME_FOREVER, ^{
            tableName = CacheDict[className];
            if (tableName == nil) {
                YYClassInfo *info = [YYClassInfo classInfoWithClass:objc_getMetaClass(cls_name)];
                if (info.methodInfos[NSStringFromSelector(@selector(tableName))]) {
                    tableName = [cls tableName];
                }
                if (al_isEmptyString(tableName)) {
                    tableName     = [className al_stringByConvertingCamelCaseToUnderscore];
                    NSInteger pos = [tableName rangeOfString:@"_"].location;
                    if (pos != NSNotFound && pos > 0) {
                        tableName = [tableName stringByAppendingString:@"_list"];
                    } else {
                        ALStringInflector *inflactor = [ALStringInflector defaultInflector];
                        tableName = [inflactor pluralize:[inflactor singularize:tableName]];
                    }
                }
                CacheDict[className] = tableName;
            }
        });
    }
    return tableName;
}


@implementation NSObject (AL_Database)

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

+ (ALDatabase *)al_database {
    static NSMutableDictionary<Class, ALDatabase *> *Caches;
    static dispatch_semaphore_t CacheLock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CacheLock = dispatch_semaphore_create(1);
        Caches = [NSMutableDictionary dictionary];
    });
    
    __block ALDatabase *database = Caches[self];
    if (database == nil) {
        with_gcd_semaphore(CacheLock, DISPATCH_TIME_FOREVER, ^{
            database = Caches[self];
            if (database == nil) {
                NSString *const selName = NSStringFromSelector(@selector(databaseIdentifier));
                Class metacls = objc_getMetaClass(object_getClassName(self));
                NSDictionary *classMethods = [YYClassInfo classInfoWithClass:metacls].methodInfos;
                if (classMethods[selName] != nil) {
                    NSString *path = [(id<ALActiveRecord>)self databaseIdentifier];
                    if (!al_isEmptyString(path)) {
                        database = [ALDatabase databaseWithPath:path keepAlive:YES];
                    }
                }
                Caches[self] = al_wrapNil(database);
            }
        });
    }
    return al_unwrapNil(database);
}

+ (nullable ALDBTableBinding *)al_tableBindings {
    if ([self al_database] == nil) { // does not bind to database
        return nil;
    }
    return [ALDBTableBinding bindingsWithClass:self];
}

+ (const ALDBPropertyList)al_allColumnProperties {
    ALDBPropertyList list;
    ALDBTableBinding *bindings = [self al_tableBindings];
    if (bindings) {
        for (ALDBColumnBinding *cb in bindings.columnBindings) {
            list.push_back(ALDBProperty(cb));
        }
    }
    return list;
}

+ (const ALDBProperty)al_columnPropertyWithProperty:(NSString *)propertyName {
    ALDBTableBinding *bindings = [self al_tableBindings];
    if (bindings) {
        NSString *colName = [bindings columnNameForProperty:propertyName];
        ALDBColumnBinding *cb = [bindings bindingForColumn:colName];
        return ALDBProperty(cb);
    }
    return ALDBProperty();
}

+ (nullable NSString *)al_columnNameForProperty:(NSString *)propertyName {
    ALDBTableBinding *bindings = [self al_tableBindings];
    return [bindings columnNameForProperty:propertyName];
}

+ (BOOL)al_inTransaction:(void (^)(BOOL *rollback))transaction {
    if (transaction) {
        return [[self al_database] al_inTransaction:transaction];
    }
    return NO;
}

- (BOOL)al_inTransaction:(void (^)(BOOL *rollback))transaction {
    return [self.class al_inTransaction:transaction];
}

#pragma mark -
+ (nullable NSArray/* <id<ALActiveRecord>> */ *)al_modelsInCondition:(const ALDBCondition &)condition {
    return [[[ALModelSelect selectModel:self properties:[self al_allColumnProperties]] where:condition] allObjects];
}

+ (nullable NSEnumerator/* <id<ALActiveRecord>> */ *)al_modelEnumeratorInCondition:(const ALDBCondition &)condition {
    return [[[ALModelSelect selectModel:self properties:[self al_allColumnProperties]] where:condition] objectEnumerator];
}

+ (nullable id<ALActiveRecord>)al_modelWithRowId:(ALDBRowIdType)rowId {
    NSEnumerator *enumerator = [self al_modelEnumeratorInCondition:ALDB_PROP(NSObject, al_rowid) == rowId];
    return [enumerator nextObject];
}

+ (NSInteger)al_modelsCountInCondition:(const ALDBCondition &)condition {
    ALDBResultSet *rs = [[[[ALModelSelect selectModel:self properties:ALDBProperty(aldb::Column::ANY).count()]
        where:condition] preparedStatement] query];
    if ([rs next]) {
        return [rs integerForColumnIndex:0];
    }
    return 0;
}

+ (nullable ALModelSelect *)al_modelFetcher {
    return [ALModelSelect selectModel:self properties:[self al_allColumnProperties]];
}

#pragma mark -
- (BOOL)al_saveOrReplace:(BOOL)replaceOnConflict {
    return [[ALModelInsert insertModel:self.class
                            properties:[self.class al_allColumnProperties]
                            onConflict:replaceOnConflict ? ALDBConflictPolicyReplace : ALDBConflictPolicyDefault]
        executeWithObjects:@[ self ]];
}

+ (BOOL)al_saveModels:(NSArray<id<ALActiveRecord>> *)models replace:(BOOL)replaceOnConflict {
    return [[ALModelInsert insertModel:self
                            properties:[self al_allColumnProperties]
                            onConflict:replaceOnConflict ? ALDBConflictPolicyReplace : ALDBConflictPolicyDefault]
            executeWithObjects: models];
}

#pragma mark -
- (const ALDBCondition)al_defaultModelUpdateCondition {
    if (!al_safeInvokeSelector(BOOL, self.class, @selector(withoutRowId))) {
#if DEBUG
        if (self.al_rowid == 0) {
            ALLogWarn(@"'rowid' is not specified. Or you can specify a condition insted.");
        }
#endif
        ALIgnoreClangDiagnostic(
            "-Wundeclared-selector",
            NSString *rowidAlias = al_safeInvokeSelector(NSString *, self.class, @selector(al_rowidAliasPropertyName));
        );
        NSString *primaryKey = rowidAlias ?: al_keypath(self.al_rowid);
        return [self.class al_columnPropertyWithProperty:primaryKey] == self.al_rowid;

    } else {
        ALDBTableBinding *tableBinding = [self.class al_tableBindings];
        NSArray *primaryKeys           = [tableBinding allPrimaryKeys];
        al_guard_or_return1(primaryKeys.count > 0, ALDBCondition(), @"no primary key defined for model: %@",
                            self.class);

        ALDBCondition condition;
        for (NSString *pn in primaryKeys) {
            NSString *cn          = [self.class al_columnNameForProperty:pn];
            ALDBColumnBinding *cb = [tableBinding bindingForColumn:cn];
            condition             = condition && (ALDBProperty(cb) == _ALColumnValueForModelProperty(self, cb));
        }
        return condition;
    }
}

- (BOOL)al_updateOrReplace:(BOOL)replaceOnConflict {
    return [[[ALModelUpdate updateModel:self.class
                             properties:[self.class al_allColumnProperties]
                             onConflict:replaceOnConflict ? ALDBConflictPolicyReplace : ALDBConflictPolicyDefault]
        where:[self al_defaultModelUpdateCondition]] executeWithObject:self];
}

- (BOOL)al_updateProperties:(NSArray<NSString *> *)propertiesNames replace:(BOOL)replaceOnConflict {
    ALDBPropertyList list;
    for (NSString *pn in propertiesNames) {
        list.push_back([self.class al_columnPropertyWithProperty:pn]);
    }
    return [[[ALModelUpdate updateModel:self.class
                             properties:list
                             onConflict:replaceOnConflict ? ALDBConflictPolicyReplace : ALDBConflictPolicyDefault]
             where:[self al_defaultModelUpdateCondition]] executeWithObject:self];
}

+ (BOOL)al_updateProperties:(NSDictionary<NSString * /* propertyName */, id> *)propertyValues
              withCondition:(const ALDBCondition &)condition
                    replace:(BOOL)replaceOnConflict {
    ALDBPropertyList list;
    for (NSString *pn in propertyValues.allKeys) {
        list.push_back([self.class al_columnPropertyWithProperty:pn]);
    }
    ALDBStatement *stmt =
        [[[ALModelUpdate updateModel:self
                          properties:list
                          onConflict:replaceOnConflict ? ALDBConflictPolicyReplace : ALDBConflictPolicyDefault]
            where:condition] preparedStatement];
    if (stmt) {
        std::list<const aldb::SQLValue> values;
        for (auto p : list) {
            ALDBColumnBinding *binding = p.columnBinding();
            id val = propertyValues[binding.propertyName];
            values.push_back([val al_SQLValue]);
        }
        values.insert(values.end(), condition.values().begin(), condition.values().end());
        return [stmt exec:values];
    }
    return NO;
}

+ (BOOL)al_updateModels:(NSArray<id<ALActiveRecord>> *)models replace:(BOOL)replaceOnConflict {
    return [self al_inTransaction:^(BOOL *_Nonnull rollback) {
        ALDBPropertyList list = [self al_allColumnProperties];
        ALDBStatement *stmt = nil;
        for (id model in models) {
            ALDBCondition condition = [model al_defaultModelUpdateCondition];
            if (stmt == nil) {
                stmt = [[[ALModelUpdate updateModel:self
                                         properties:list
                                         onConflict:replaceOnConflict
                                                       ? ALDBConflictPolicyReplace
                                                       : ALDBConflictPolicyDefault]
                    where:condition] preparedStatement];
                if (stmt == nil) {
                    return;
                }
            }
            std::list<const aldb::SQLValue> values;
            for (auto p : list) {
                ALDBColumnBinding *binding = p.columnBinding();
                id val = _ALColumnValueForModelProperty(model, binding);
                values.push_back([val al_SQLValue]);
            }
            values.insert(values.end(), condition.values().begin(), condition.values().end());
            if (![stmt exec:values]) {
                // exit?
            }
        }
    }];
}

#pragma mark -
- (BOOL)al_deleteModel {
    return [self.class al_deleteModelsWithCondition:[self al_defaultModelUpdateCondition]];
}

+ (BOOL)al_deleteModelsWithCondition:(const ALDBCondition &)condition {
    return [[[[ALModelDelete deleteModel:self] where:condition] preparedStatement] exec];
}

#pragma mark -
@end

