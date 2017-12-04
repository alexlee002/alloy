//
//  NSObject+ALDBBindings.m
//  alloy
//
//  Created by Alex Lee on 01/11/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "NSObject+ALDBBindings.h"
#import "ALLock.h"
#import "NSString+ALHelper.h"
#import "ALActiveRecord.h"
#import "YYClassInfo.h"
#import "ALStringInflector.h"
#import "ALDBTableBinding_Private.h"
#import "ALLogger.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation NSObject (ALDBBindings)
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
                static NSString *selName = NSStringFromSelector(@selector(databaseIdentifier));
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
        ALDBColumnBinding *cb = ALCastToTypeOrNil([bindings bindingForColumn:colName], ALDBColumnBinding);
        if (cb != nil) {
            return ALDBProperty(cb);
        } else {
            ALLogWarn(@"No column binding with property '%@' in model '%@'.", propertyName, self);
            return ALDBProperty(colName);
        }
    }
    ALLogWarn(@"no property '%@' defined in model '%@'.", propertyName, self);
    return ALDBProperty();
}

+ (nullable NSString *)al_columnNameForProperty:(NSString *)propertyName {
    ALDBTableBinding *bindings = [self al_tableBindings];
    return [bindings columnNameForProperty:propertyName];
}

@end

NSString *ALTableNameForModel(__unsafe_unretained Class cls) {
    static NSString *const kSelectorName = NSStringFromSelector(@selector(tableName));
    
    NSString *tableName = nil;
    const char *cls_name = class_getName(cls);
    YYClassInfo *info = [YYClassInfo classInfoWithClass:objc_getMetaClass(cls_name)];
    if (info.methodInfos[kSelectorName]) {
        tableName = [cls tableName];
    } else {
        tableName = [@(cls_name) al_stringByConvertingCamelCaseToUnderscore];
        ALStringInflector *inflactor = [ALStringInflector defaultInflector];
        tableName = [inflactor pluralize:[inflactor singularize:tableName]];
    }
    return tableName;
}

