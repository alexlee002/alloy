//
//  __ALModelMeta+ActiveRecord.m
//  patchwork
//
//  Created by Alex Lee on 22/06/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "__ALModelMeta+ActiveRecord.h"
#import "ALSQLValue.h"
#import "ALDBColumnDefine.h"
#import "ALDBTypeCoding.h"
#import "__ALModelHelper.h"
#import "ALActiveRecord.h"
#import "ALUtilitiesHeader.h"
#import <objc/message.h>
extern "C" {
    #import "NSString+ALHelper.h"
}

@implementation _ALPropertyColumnBindings

+ (instancetype)bindingWithPropertyMeta:(_ALModelPropertyMeta *)meta column:(NSString *)columnName {
    _ALPropertyColumnBindings *bindings = [[self alloc] init];

    bindings->_propertyMeta = meta;
    bindings->_columnName   = [columnName copy];
    ALDBColumnType colType  = [ALDBTypeCoding columnTypeForObjCType:meta->_info.typeEncoding.UTF8String];
    bindings->_column =
        std::shared_ptr<ALDBColumnDefine>(new ALDBColumnDefine(ALDBColumn(columnName.UTF8String), colType));
    
    return bindings;
}

@end

@implementation _ALModelTableBindings

+ (instancetype)bindingsWithClass:(Class)cls {
    return [self bindingsWithModelMeta:[_ALModelMeta metaWithClass:cls]];
}

+ (instancetype)bindingsWithModelMeta:(_ALModelMeta *)meta {
    static CFMutableDictionaryRef cache;
    static dispatch_semaphore_t lock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks,
                                          &kCFTypeDictionaryValueCallBacks);
        lock = dispatch_semaphore_create(1);
    });

    Class cls = meta->_classInfo.cls;
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    _ALModelTableBindings *bindings =
        (__bridge _ALModelTableBindings *) CFDictionaryGetValue(cache, (__bridge const void *) (cls));
    dispatch_semaphore_signal(lock);

    if (!bindings) {
        bindings = [[_ALModelTableBindings alloc] initWithModelMeta:meta];
        if (bindings) {
            dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
            CFDictionarySetValue(cache, (__bridge const void *) (cls), (__bridge const void *) (bindings));
            dispatch_semaphore_signal(lock);
        }
    }

    return bindings;
}

- (instancetype)initWithModelMeta:(_ALModelMeta *)meta  {
    if (meta == nil) {
        return nil;
    }
    
    self = [super init];
    _modelMeta = meta;
    
    [self loadPropertyColumnBindings];
    
    return self;
}

- (void)loadPropertyColumnBindings {
    //    #define PropertyColumnMap(p) [self p]
    //    NSArray *a = @[PropertyColumnMap(column1), PropertyColumnMap(column2)];

    NSSet *blacklist =
        [_ALModelHelper model:_modelMeta->_classInfo.cls propertySetWithSelector:@selector(columnPropertyBlacklist)];
    NSSet *whitelist =
        [_ALModelHelper model:_modelMeta->_classInfo.cls propertySetWithSelector:@selector(columnPropertyWhitelist)];

    // Create all property metas.
    NSMutableDictionary<NSString *, _ALPropertyColumnBindings *> *columnBindings = [NSMutableDictionary dictionary];
    for (_ALModelPropertyMeta *propmeta in _modelMeta->_allPropertyMetasDict.allValues) {
        NSString *propname = propmeta->_name;
        if ([blacklist containsObject:propname]) {
            continue;
        }
        if (whitelist && ![whitelist containsObject:propname]) {
            continue;
        }

        NSString *colname = [self columnNameForProperty:propname];
        _ALPropertyColumnBindings *binding =
            [_ALPropertyColumnBindings bindingWithPropertyMeta:propmeta column:colname];
        if (!binding) {
            continue;
        }
        if (columnBindings[propname]) {
            continue;
        }
        columnBindings[propname] = binding;
    }

    if (columnBindings.count > 0) {
        _propertyColumnMapper = columnBindings;
    }
}

- (void)loadTableConstraints {
    NSString *pk = nil;
    NSMutableArray *uk = [NSMutableArray array];
    for (_ALPropertyColumnBindings *columnBinding in _propertyColumnMapper.allValues) {
        auto columnDef = columnBinding->_column;
        if (columnDef->is_primary()) {
            ALAssert(pk == nil, @"Duplicated primary key!");
            pk = @(std::string(columnDef->column()).c_str());
        } else if (columnDef->is_unique()) {
            [uk addObject:@(std::string(columnDef->column()).c_str())];
        }
    }
    Class cls = _modelMeta->_classInfo.cls;
    NSArray<NSString *> *primaryKeys = al_safeInvokeSelector(NSArray *, cls, @selector(primaryKeys));

    if (primaryKeys.count == 1 && pk != nil && ![primaryKeys.firstObject isEqualToString:pk]) {
        ALAssert(NO, @"Duplicated primary key!");
        _allPrimaryKeys = @[pk];
    } else if (primaryKeys.count == 0 && pk != nil) {
        _allPrimaryKeys = @[pk];
    } else {
        _allPrimaryKeys = primaryKeys;
    }
    
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
    
    _allIndexeKeys = al_safeInvokeSelector(NSArray *, cls, @selector(indexKeys));
}

- (NSString *)columnNameForProperty:(NSString *)propertyName {
    Class cls = _modelMeta->_classInfo.cls;
    if ([(id)cls respondsToSelector:@selector(modelCustomColumnNameMapper)]) {
        NSDictionary *customMapper = [(id<ALActiveRecord>)cls modelCustomColumnNameMapper];
        NSString *colname = customMapper[propertyName];
        if (!al_isEmptyString(colname)) {
            return colname;
        }
    }
    
    return [propertyName al_stringByConvertingCamelCaseToUnderscore];
}

@end
