//
//  ALModel_Define.m
//  patchwork
//
//  Created by Alex Lee on 2/25/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALModel_Define.h"
#import "YYClassInfo.h"
#import "ALOCRuntime.h"
#import <BlocksKit.h>
#import "ALUtilitiesHeader.h"
#import "NSString+ALHelper.h"
#import <YYModel.h>
#import <objc/message.h>
#import "ALLogger.h"
#import "ALModel+ActiveRecord.h"


NSString * const kModelRowidDidChangeNotification = @"ModelRowidDidChangeNotification";

/**
 *  copy specified properties from 'from' to 'to'
 *
 *  @param copyingProperties     specified properties to copied
 *
 */
static AL_FORCE_INLINE void copyProperties(ALModel *from, ALModel *to,
                                        NSDictionary<NSString *, YYClassPropertyInfo *> *copyingProperties);


@implementation ALModel

- (instancetype)init {
    self = [super init];
    if (self) {
#ifdef AL_ENABLE_ROWID_TRIGGER
        // @see Active record category
        IgnoreClangDiagnostic("-Wundeclared-selector", [[NSNotificationCenter defaultCenter]
                                                           addObserver:self
                                                              selector:@selector(handleRecordConflictNotification:)
                                                                  name:kModelRowidDidChangeNotification
                                                                object:nil];);
#endif
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end


@implementation ALModel (ALRuntime)

+ (nullable instancetype)modelCopyFromModel:(__kindof ALModel *)other {
    ALModel *model = [[self alloc] init];
    [model modelCopyProperties:nil fromModel:other];
    return model;
}

+ (nullable instancetype)modelCopyFromModel:(__kindof ALModel *)other withProperties:(NSArray<NSString *> *)properties {
    ALModel *model = [[self alloc] init];
    [model modelCopyProperties:properties fromModel:other];
    return model;
}

+ (nullable instancetype)modelCopyFromModel:(__kindof ALModel *)other
                          excludeProperties:(NSArray<NSString *> *)properties {
    
    if (other == nil) {
        return nil;
    }
    ALModel *model = [[self alloc] init];
    
    Class clazz = [self.class al_commonAncestorWithClass:other.class];
    if (clazz != self.class || ![clazz isSubclassOfClass:[ALModel class]]) {
        return nil;
    }
    NSDictionary<NSString *, YYClassPropertyInfo *> *modelProperties = [clazz allModelProperties];
    modelProperties = [modelProperties bk_reject:^BOOL(NSString *key, YYClassPropertyInfo *p) {
        return [properties containsObject:key];
    }];
    
    copyProperties(other, model, modelProperties);
    return model;
}

// NSCopying protocol
- (id)copyWithZone:(nullable NSZone *)zone {
    ALModel *model = [[self.class alloc] init];
    copyProperties(self, model, [self.class allModelProperties]);
    return model;
}

+ (NSDictionary<NSString *, YYClassPropertyInfo *> *)allModelProperties {
    NSMutableDictionary<NSString *, YYClassPropertyInfo *> *allProperties = [NSMutableDictionary dictionary];
    YYClassInfo *info = [YYClassInfo classInfoWithClass:self];
    while (info && info.cls != NSObject.class) {
        [allProperties addEntriesFromDictionary:info.propertyInfos];
        info = info.superClassInfo;
    }
    return allProperties;
}

+ (NSDictionary<NSString *, YYClassIvarInfo *> *)allModelIvars {
    NSMutableDictionary<NSString *, YYClassIvarInfo *> *allIvars = [NSMutableDictionary dictionary];
    YYClassInfo *info = [YYClassInfo classInfoWithClass:self];
    while (info && info.cls != NSObject.class) {
        [allIvars addEntriesFromDictionary:info.ivarInfos];
        info = info.superClassInfo;
    }
    return allIvars;
}

+ (NSDictionary<NSString *, YYClassMethodInfo *> *)allModelMethods {
    NSMutableDictionary<NSString *, YYClassMethodInfo *> *allMethods = [NSMutableDictionary dictionary];
    YYClassInfo *info = [YYClassInfo classInfoWithClass:self];
    while (info && info.cls != NSObject.class) {
        [allMethods addEntriesFromDictionary:info.methodInfos];
        info = info.superClassInfo;
    }
    return allMethods;
}

+ (BOOL)hasModelProperty:(NSString *)propertyName {
    return [self allModelProperties][propertyName] != nil;
}


/**
 * copy properties from 'other' to self
 *
 * @param properties    name of properties to be copied，
 *                      if it's not empty， copy the specified(ignore blacklist, whilelist)
 *                      otherwise, copy the default values (@see "-yy_modelCopy")
 * @param other         model to copy。 If self and other are different class type, copy the common properties only.
 */
- (void)modelCopyProperties:(nullable NSArray<NSString *> *)properties fromModel:(__kindof ALModel *)other {
    if (other == nil) {
        return;
    }
    Class clazz = [self.class al_commonAncestorWithClass:other.class];
    NSDictionary<NSString *, YYClassPropertyInfo *> *modelProperties = [clazz allModelProperties];
    if (properties == nil) {
        NSSet *blacklist = [self.class respondsToSelector:@selector(modelPropertyBlacklist)]
        ? [NSSet setWithArray:[self.class modelPropertyBlacklist]]
        : nil;
        blacklist = blacklist.count > 0 ? blacklist : nil;
        
        NSSet *whitelist = [self.class respondsToSelector:@selector(modelPropertyWhitelist)]
        ? [NSSet setWithArray:[self.class modelPropertyWhitelist]]
        : nil;
        whitelist = whitelist.count > 0 ? whitelist : nil;
        
        if (blacklist != nil || whitelist != nil) {
            modelProperties = [modelProperties bk_reject:^BOOL(NSString *key, YYClassPropertyInfo *p) {
                return (blacklist != nil && [blacklist containsObject:key]) ||
                (whitelist != nil && ![whitelist containsObject:key]);
            }];
        }
    } else {
        modelProperties = [modelProperties bk_select:^BOOL(NSString *key, YYClassPropertyInfo *p) {
            return [properties containsObject:key];
        }];
    }
    
    copyProperties(other, self, modelProperties);
}

@end

static AL_FORCE_INLINE void copyProperties(ALModel *from, ALModel *to,
                                        NSDictionary<NSString *, YYClassPropertyInfo *> *copyingProperties) {
    if (from == nil || to == nil || copyingProperties.count == 0) {
        return;
    }
    [copyingProperties bk_each:^(NSString *name, YYClassPropertyInfo *p) {
        SEL getter = p.getter;
        SEL setter = p.setter;
        
        if (getter == nil || ![from respondsToSelector:getter]) {
            return;
        }
        if (setter == nil || ![to respondsToSelector:setter]) {
            if (!al_isEmptyString(p.ivarName)) {
                id value = [from valueForKey:p.ivarName];
                [to setValue:value forKey:p.ivarName];
            }
            return;
        }
        
        switch (p.type & YYEncodingTypeMask) {
            case YYEncodingTypeBool: {
                bool num = ((bool (*)(id, SEL))(void *) objc_msgSend)((id) from, getter);
                ((void (*)(id, SEL, bool))(void *) objc_msgSend)((id) to, setter, num);
            } break;
            case YYEncodingTypeInt8:
            case YYEncodingTypeUInt8: {
                uint8_t num = ((bool (*)(id, SEL))(void *) objc_msgSend)((id) from, getter);
                ((void (*)(id, SEL, uint8_t))(void *) objc_msgSend)((id) to, setter, num);
            } break;
            case YYEncodingTypeInt16:
            case YYEncodingTypeUInt16: {
                uint16_t num = ((uint16_t (*)(id, SEL))(void *) objc_msgSend)((id) from, getter);
                ((void (*)(id, SEL, uint16_t))(void *) objc_msgSend)((id) to, setter, num);
            } break;
            case YYEncodingTypeInt32:
            case YYEncodingTypeUInt32: {
                uint32_t num = ((uint32_t (*)(id, SEL))(void *) objc_msgSend)((id) from, getter);
                ((void (*)(id, SEL, uint32_t))(void *) objc_msgSend)((id) to, setter, num);
            } break;
            case YYEncodingTypeInt64:
            case YYEncodingTypeUInt64: {
                uint64_t num = ((uint64_t (*)(id, SEL))(void *) objc_msgSend)((id) from, getter);
                ((void (*)(id, SEL, uint64_t))(void *) objc_msgSend)((id) to, setter, num);
            } break;
            case YYEncodingTypeFloat: {
                float num = ((float (*)(id, SEL))(void *) objc_msgSend)((id) from, getter);
                ((void (*)(id, SEL, float))(void *) objc_msgSend)((id) to, setter, num);
            } break;
            case YYEncodingTypeDouble: {
                double num = ((double (*)(id, SEL))(void *) objc_msgSend)((id) from, getter);
                ((void (*)(id, SEL, double))(void *) objc_msgSend)((id) to, setter, num);
            } break;
            case YYEncodingTypeLongDouble: {
                long double num = ((long double (*)(id, SEL))(void *) objc_msgSend)((id) from, getter);
                ((void (*)(id, SEL, long double))(void *) objc_msgSend)((id) to, setter, num);
            } break;
                
            case YYEncodingTypeObject:
            case YYEncodingTypeClass:
            case YYEncodingTypeBlock: {
                id value = ((id (*)(id, SEL))(void *) objc_msgSend)((id)from, getter);
                ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)to, setter, value);
            } break;
            case YYEncodingTypeSEL:
            case YYEncodingTypePointer:
            case YYEncodingTypeCString: {
                size_t value = ((size_t (*)(id, SEL))(void *) objc_msgSend)((id)from, getter);
                ((void (*)(id, SEL, size_t))(void *) objc_msgSend)((id)to, setter, value);
            } break;
            case YYEncodingTypeStruct:
            case YYEncodingTypeUnion: {
                @try {
                    NSValue *value = [from valueForKey:p.name];
                    if (value) {
                        [to setValue:value forKey:p.name];
                    }
                } @catch (NSException *exception) {
                    ALLogWarn(@"%@", exception);
                }
            } break;
                
            default:
                ALLogWarn(@"Not supported property name %@, type: %@", p.name, @(p.type));
                break;
        }
    }];
}

