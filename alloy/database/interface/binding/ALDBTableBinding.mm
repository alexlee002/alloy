//
//  ALDBTableBinding.m
//  alloy
//
//  Created by Alex Lee on 08/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDBTableBinding_Private.h"
#import "ALDBColumnBinding_Private.h"
#import "ALMacros.h"
#import "NSString+ALHelper.h"
#import "BlocksKit+ALExtension.h"
#import "column.hpp"
#import "column_index.hpp"
#import "ALActiveRecord.h"
#import "NSObject+ALDBBindings.h"
#import <objc/message.h>
#import <BlocksKit/BlocksKit.h>

@implementation ALDBTableBinding {
    NSArray<ALDBColumnBinding *> * _columnBindings; // ordered
    NSDictionary<NSString */*columnName*/, ALDBColumnBinding *> * _columnBindingsDict;
    
    NSArray<NSString */*propertyName*/> *            _allPrimaryKeys;
    NSArray<NSArray<NSString */*propertyName*/> *> * _allUniqueKeys;
    NSArray<NSArray<NSString */*propertyName*/> *> * _allIndexKeys;
}

+ (instancetype)bindingsWithClass:(Class)cls {
    return [self bindingsWithModelMeta:[_ALModelMeta metaWithClass:cls]];
}

+ (instancetype)bindingsWithModelMeta:(_ALModelMeta *)meta {
    static CFMutableDictionaryRef cache;
    static dispatch_semaphore_t lock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = CFDictionaryCreateMutable(CFAllocatorGetDefault(),
                                          0,
                                          &kCFTypeDictionaryKeyCallBacks,
                                          &kCFTypeDictionaryValueCallBacks);
        lock = dispatch_semaphore_create(1);
    });

    Class cls = meta->_info.cls;
    ALDBTableBinding *bindings =
        (__bridge ALDBTableBinding *) CFDictionaryGetValue(cache, (__bridge const void *) (cls));

    if (!bindings) {
        dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
        bindings = (__bridge ALDBTableBinding *) CFDictionaryGetValue(cache, (__bridge const void *) (cls));
        if (!bindings) {
            bindings = [[ALDBTableBinding alloc] initWithModelMeta:meta];
            if (bindings) {
                CFDictionarySetValue(cache, (__bridge const void *) (cls), (__bridge const void *) (bindings));
            }
        }
        dispatch_semaphore_signal(lock);
    }

    return bindings;
}

- (instancetype)initWithModelMeta:(_ALModelMeta *)meta  {
    if (meta == nil) {
        return nil;
    }
    
    self = [super init];
    _modelMeta = meta;
    
    [self loadBindings];
    
    return self;
}

- (Class)bindingClass {
    return _modelMeta->_info.cls;
}

- (NSString *)columnNameForProperty:(NSString *)propertyName {
    if ([propertyName isEqualToString:al_keypathForClass(NSObject, al_rowid)]) {
        return @(aldb::Column::ROWID.name().c_str());
    }
    Class cls = _modelMeta->_info.cls;
    NSDictionary *customMapper = al_safeInvokeSelector(NSDictionary *, cls, @selector(modelCustomColumnNameMapper));
    NSString *colName = customMapper[propertyName];
    return colName ?: [propertyName al_stringByConvertingCamelCaseToUnderscore];
}

- (NSArray<ALDBColumnBinding *> *)columnBindings {
    return _columnBindings;
}

- (ALDBColumnBinding *)bindingForColumn:(NSString *)colName {
    return _columnBindingsDict[colName];
}

- (ALDBIndexBinding *)indexBindingWithProperties:(NSArray<NSString *> *)indexPropertyNames unique:(BOOL)unique {
    NSString *tableName = ALTableNameForModel(_modelMeta->_info.cls);
    ALDBIndexBinding *binding = [ALDBIndexBinding indexBindingWithTableName:tableName isUnique:unique];
    for (NSString *pn in indexPropertyNames) {
        NSString *cn = [self columnNameForProperty:pn];
        [binding addIndexColumn:aldb::Column(cn.UTF8String)];
    }
    return binding;
}

- (NSArray<NSString */*propertyName*/> *)allPrimaryKeys {
    return _allPrimaryKeys;
}

- (NSArray<NSArray<NSString */*propertyName*/> *> *)allUniqueKeys {
    return _allUniqueKeys;
}

- (NSArray<NSArray<NSString */*propertyName*/> *> *)allIndexKeys {
    return _allIndexKeys;
}

#pragma mark -
- (void)loadBindings {
    // Create all property metas.
    NSMutableDictionary<NSString * /*columnName*/, ALDBColumnBinding *> *columnsDict =
        [NSMutableDictionary dictionary];
    
    [self loadColumnBindingsInto:columnsDict];
    [self loadTableConstraintsWithColumnsDict:columnsDict];
    
    if (columnsDict.count > 0) {
        _columnBindingsDict = [columnsDict copy];
        _columnBindings = [_columnBindingsDict.allValues sortedArrayUsingComparator:[self columnOrderComparator]];
    }
}

- (void)loadColumnBindingsInto:(NSMutableDictionary<NSString * /*columnName*/, ALDBColumnBinding *> *)columnsDict {
    Class modelCls = _modelMeta->_info.cls;
    NSArray *properties = al_safeInvokeSelector(NSArray *, modelCls, @selector(columnPropertyBlacklist));
    NSSet *blacklist    = ALCastToTypeOrNil(properties, NSArray).count > 0 ? [NSSet setWithArray:properties] : nil;
    
    properties       = al_safeInvokeSelector(NSArray *, modelCls, @selector(columnPropertyWhitelist));
    NSSet *whitelist = ALCastToTypeOrNil(properties, NSArray).count > 0 ? [NSSet setWithArray:properties] : nil;
    
    for (_ALModelPropertyMeta *propmeta in _modelMeta->_allPropertyMetasDict.allValues) {
        NSString *propname = propmeta->_name;
        if ([blacklist containsObject:propname]) {
            continue;
        }

        BOOL neededRowId = NO; // mark if this is rowid column and this column is needed
        if (whitelist && ![whitelist containsObject:propname]) {
            ALIgnoreClangDiagnostic("-Wundeclared-selector",
                if (!al_safeInvokeSelector(BOOL, modelCls, @selector(al_hasRowidAlias)) &&
                    !al_safeInvokeSelector(BOOL, modelCls, @selector(withoutRowId))     &&
                    [propname isEqualToString:al_keypathForClass(NSObject, al_rowid)]) {
                    // if rowid column is needed
                    neededRowId = YES;
                });
            if (!neededRowId) {
                continue;
            }
        }

        NSString *colname = [self columnNameForProperty:propname];
        if (columnsDict[colname]) {
            continue;
        }
        
        ALDBColumnBinding *binding =
            [ALDBColumnBinding bindingWithModelMeta:_modelMeta propertyMeta:propmeta column:colname];
        if (!binding) {
            continue;
        }
        columnsDict[colname] = binding;
    }
}

- (void)loadTableConstraintsWithColumnsDict:(NSMutableDictionary<NSString * /*columnName*/, ALDBColumnBinding *> *)columnsDict {
    NSString *pk = nil;
    NSMutableArray *uk = [NSMutableArray array];
    for (ALDBColumnBinding *columnBinding in columnsDict.allValues) {
        auto columnDef = [columnBinding columnDefine];
        if (columnDef->is_primary()) {
            ALAssert(pk == nil, @"Duplicated primary key!");
            pk = [columnBinding propertyName];
        } else if (columnDef->is_unique()) {
            [uk addObject:[columnBinding propertyName]];
        }
    }
    Class cls = _modelMeta->_info.cls;
    NSArray<NSString *> *primaryKeys = al_safeInvokeSelector(NSArray *, cls, @selector(primaryKeys));
    
    if (pk == nil) {
        _allPrimaryKeys = primaryKeys;
    } else if (primaryKeys.count == 0) {
        _allPrimaryKeys = @[pk];
    } else if (![primaryKeys isEqualToArray:@[pk]]) {
        ALAssert(NO, @"Duplicated primary key defined! Model:%@.", cls);
        _allPrimaryKeys = @[pk];
    }
    //if no primary key, make "rowid" as default
    if (_allPrimaryKeys.count == 0) {
        NSString *rownidColName = @(aldb::Column::ROWID.name().c_str());
        if (columnsDict[rownidColName]) {
            _allPrimaryKeys = @[rownidColName];
        }
    }
    ALAssert(_allPrimaryKeys.count > 0, @"No primary key defined! Model: %@", cls);
    
    NSArray<NSArray<NSString *> *> *uniqueKeys = al_safeInvokeSelector(NSArray *, cls, @selector(uniqueKeys));
    if (uk.count > 0) {
        NSMutableArray *allUKs = [uk mutableCopy];
        for (NSArray *keys in uniqueKeys) {
            if (![allUKs containsObject:keys]) {
                [allUKs addObject:keys];
            }
        }
        _allUniqueKeys = [allUKs copy];
    } else {
        _allUniqueKeys = uniqueKeys;
    }
    
    _allIndexKeys = al_safeInvokeSelector(NSArray *, cls, @selector(indexKeys));
}

- (NSComparator)columnOrderComparator {
    Class cls = _modelMeta->_info.cls;
    
    NSComparator cmptor = al_safeInvokeSelector(NSComparator, cls, @selector(columnOrderComparator));
    if (cmptor) {
        return cmptor;
    }
    
    NSArray *list = al_safeInvokeSelector(NSArray *, cls, @selector(columnPropertyWhitelist)) ?: [[@[
        al_wrapNil(_allPrimaryKeys), al_wrapNil([_allUniqueKeys al_flatten]), al_wrapNil([_allIndexKeys al_flatten])
    ] bk_reject:^BOOL(id obj) {
        return obj == NSNull.null;
    }] al_flatten];
    NSOrderedSet *keyList = [NSOrderedSet orderedSetWithArray:list];

    NSString *rowidPN = al_keypathForClass(NSObject, al_rowid);
    return ^NSComparisonResult(ALDBColumnBinding *col1, ALDBColumnBinding *col2) {
        NSString *pn1 = [col1 propertyName];
        NSString *pn2 = [col2 propertyName];
        
        if ([pn1 isEqualToString:rowidPN]) {
            return NSOrderedAscending;
        } else if ([pn2 isEqualToString:rowidPN]) {
            return NSOrderedDescending;
        }

        NSInteger idx1 = [keyList indexOfObject:pn1];
        NSInteger idx2 = [keyList indexOfObject:pn2];

        if (idx1 != NSNotFound || idx2 != NSNotFound) {
            return [@(idx1) compare:@(idx2)];
        } else {
            return [pn1 compare:pn2];
        }
    };
}

#pragma mark -
@end

