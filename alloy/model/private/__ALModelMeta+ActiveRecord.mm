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
#import "ALDBColumnProperty.h"
#import "ALDBTypeCoding.h"
#import "__ALModelHelper.h"
#import "ALActiveRecord.h"
#import "ALUtilitiesHeader.h"
#import <objc/message.h>
#import "NSString+ALHelper.h"
#import "__ALPropertyColumnBindings+private.h"
#import "NSObject+AL_ActiveRecord.h"
#import <BlocksKit.h>
#import "BlocksKitExtension.h"

static NSString *const kRowId = @"rowid";

@implementation _ALModelTableBindings {
    NSMutableDictionary<NSString */*propertyName*/, NSString */*columnName*/> *_propertyColumnNameMapper; //lazy fill
    dispatch_semaphore_t _dsem;
}

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
    _dsem = dispatch_semaphore_create(1);
    
    [self loadPropertyColumnBindings];
    [self cacheColumnProperties];
    
    return self;
}

- (void)loadPropertyColumnBindings {
    Class modelCls = _modelMeta->_classInfo.cls;
    NSSet *blacklist = [_ALModelHelper model:modelCls propertySetWithSelector:@selector(columnPropertyBlacklist)];
    NSSet *whitelist = [_ALModelHelper model:modelCls propertySetWithSelector:@selector(columnPropertyWhitelist)];

    // Create all property metas.
    NSMutableDictionary<NSString * /*columnName*/, ALPropertyColumnBindings *> *columnsDict =
        [NSMutableDictionary dictionary];

    for (_ALModelPropertyMeta *propmeta in _modelMeta->_allPropertyMetasDict.allValues) {
        NSString *propname = propmeta->_name;
        if ([blacklist containsObject:propname]) {
            continue;
        }
        if (whitelist && ![whitelist containsObject:propname]) {
            continue;
        }

        NSString *colname = [self columnNameForProperty:propname];
        if (columnsDict[colname]) {
            continue;
        }
        
        ALPropertyColumnBindings *binding =
            [ALPropertyColumnBindings bindingWithModel:_modelMeta->_classInfo.cls propertyMeta:propmeta column:colname];
        if (!binding) {
            continue;
        }

        NSString *tmpPN = [propname al_stringbyUppercaseFirst];
        NSString *selName = [@"customColumnValueTransformFrom" stringByAppendingString:tmpPN];
        NSDictionary *methods = _modelMeta->_classInfo.methodInfos;
        if (methods[selName]) {
            binding->_customGetter = NSSelectorFromString(selName);
        }
        
        selName = [NSString stringWithFormat:@"customTransform%@FromResultSet:atIndex:", tmpPN];
        if (methods[selName]) {
            binding->_customSetter = NSSelectorFromString(selName);
        }
        
        columnsDict[colname] = binding;
//        [allColumns addObject:binding];
    }

    [self loadTableConstraintsWithColumns:columnsDict.allValues];

    if (_allPrimaryKeys.count == 0 && !al_safeInvokeSelector(BOOL, modelCls, @selector(withoutRowId))) {
        // add rowid column
        NSString *rowidColName = @(ALDBColumn::s_rowid.to_string().c_str());
        ALPropertyColumnBindings *rowidBinding = [ALPropertyColumnBindings
            bindingWithModel:_modelMeta->_classInfo.cls
                propertyMeta:_modelMeta->_allPropertyMetasDict[al_keypathForClass(NSObject, al_rowid)]
                      column:rowidColName];
        rowidBinding->_columnDef->as_primary(ALDBOrderDefault, ALDBConflictPolicyDefault, true);

        columnsDict[rowidColName] = rowidBinding;
        _allPrimaryKeys           = @[ al_keypathForClass(NSObject, al_rowid) ];
    }

    if (columnsDict.count > 0) {
        _columnsDict = [columnsDict copy];
        _allColumns = [_columnsDict.allValues sortedArrayUsingComparator:[self columnOrderComparator]];
    }
}

- (void)loadTableConstraintsWithColumns:(NSArray<ALPropertyColumnBindings *> *)columns {
    NSString *pk = nil;
    NSMutableArray *uk = [NSMutableArray array];
    for (ALPropertyColumnBindings *columnBinding in columns) {
        auto columnDef = [columnBinding columnDefine];
        if (columnDef.is_primary()) {
            ALAssert(pk == nil, @"Duplicated primary key!");
            pk = [columnBinding propertyName];
        } else if (columnDef.is_unique()) {
            [uk addObject:[columnBinding propertyName]];
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
    dispatch_semaphore_wait(_dsem, DISPATCH_TIME_FOREVER);
    if (_propertyColumnNameMapper == nil) {
        _propertyColumnNameMapper = [@{ al_keypathForClass(NSObject, al_rowid) : kRowId } mutableCopy];
    }

    NSString *colname = _propertyColumnNameMapper[propertyName];
    if (colname == nil) {
        Class cls = _modelMeta->_classInfo.cls;
        if ([(id) cls respondsToSelector:@selector(modelCustomColumnNameMapper)]) {
            NSDictionary *customMapper = [(id<ALActiveRecord>) cls modelCustomColumnNameMapper];
            NSString *tmpColName       = customMapper[propertyName];
            if (!al_isEmptyString(tmpColName)) {
                _propertyColumnNameMapper[propertyName] = tmpColName;
                colname = tmpColName;
            }
        }

        colname = [propertyName al_stringByConvertingCamelCaseToUnderscore];
        _propertyColumnNameMapper[propertyName] = colname;
    }
    dispatch_semaphore_signal(_dsem);
    return colname;
}

- (NSComparator)columnOrderComparator {
    Class cls = _modelMeta->_classInfo.cls;
    NSArray *list = al_safeInvokeSelector(NSArray *, cls, @selector(columnPropertyWhitelist)) ?: [[@[
        al_wrapNil(_allPrimaryKeys), al_wrapNil([_allUniqueKeys al_flatten]), al_wrapNil([_allIndexeKeys al_flatten])
    ] bk_reject:^BOOL(id obj) {
        return obj == NSNull.null;
    }] al_flatten];
    
    NSString *rowidPN = al_keypathForClass(NSObject, al_rowid);
    return ^NSComparisonResult(ALPropertyColumnBindings *col1, ALPropertyColumnBindings *col2) {
        NSString *pn1 = [col1 propertyName];
        NSString *pn2 = [col2 propertyName];
        if ([pn1 isEqualToString:rowidPN]) {
            return NSOrderedAscending;
        } else if ([pn2 isEqualToString:rowidPN]) {
            return NSOrderedDescending;
        }
        
        NSInteger idx1 = [list indexOfObject:pn1];
        NSInteger idx2 = [list indexOfObject:pn2];
        
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

- (void)cacheColumnProperties {
    [_allColumns bk_each:^(ALPropertyColumnBindings *binding) {
        _allColumnProperties.push_back(ALDBColumnProperty([binding columnName], binding));
    }];
}

@end
