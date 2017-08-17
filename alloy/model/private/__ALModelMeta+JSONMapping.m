//
//  __ALModelMeta+JSONMapping.m
//  patchwork
//
//  Created by Alex Lee on 22/06/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "__ALModelMeta+JSONMapping.h"
#import <objc/message.h>
#import "YYModel.h"

@implementation _ALPropertyJSONMeta

+ (instancetype)metaWithPropertyMeta:(_ALModelPropertyMeta *)meta genericClass:(Class)generic {
    _ALPropertyJSONMeta *mapping = [[self alloc] init];
    mapping->_meta = meta;
    
    if (!generic && meta->_info.protocols.count > 0) {
        generic = [self pseudoGenericClassWithProtocols:meta->_info.protocols];
    }
    if (generic) {
        mapping->_hasCustomClassFromDictionary = [generic respondsToSelector:@selector(modelCustomClassForDictionary:)];
    } else if (meta->_cls && meta->_nsType == YYEncodingTypeNSUnknown) {
        mapping->_hasCustomClassFromDictionary = [meta->_cls respondsToSelector:@selector(modelCustomClassForDictionary:)];
    }
    
    return mapping;
}

// support pseudo generic class with protocol name
+ (Class)pseudoGenericClassWithProtocols:(NSArray<NSString *> *)protocols {
    for (NSString *protocol in protocols) {
        Class cls = objc_getClass(protocol.UTF8String);
        if (cls) {
            return cls;
        }
    }
    return Nil;
}
@end

/////////////////////////////////////////////////////////////////
@implementation _ALModelJSONMeta

+ (instancetype)metaWithClass:(Class)cls {
    return [self metaWithModelMeta:[_ALModelMeta metaWithClass:cls]];
}

+ (instancetype)metaWithModelMeta:(_ALModelMeta *)meta {
    if (!meta) {
        return nil;
    }
    static CFMutableDictionaryRef cache;
    static dispatch_semaphore_t lock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        lock = dispatch_semaphore_create(1);
    });
    
    Class cls = meta->_classInfo.cls;
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    _ALModelJSONMeta *modelMeta = CFDictionaryGetValue(cache, (__bridge const void *)(cls));
    dispatch_semaphore_signal(lock);
    
    if (!modelMeta) {
        modelMeta = [[_ALModelJSONMeta alloc] initWithModelMeta:meta];
        if (modelMeta) {
            dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
            CFDictionarySetValue(cache, (__bridge const void *)(cls), (__bridge const void *)(modelMeta));
            dispatch_semaphore_signal(lock);
        }
    }
    
    return modelMeta;
}

- (instancetype)initWithModelMeta:(_ALModelMeta *)meta {
    if (!meta) { return nil; }
    
    self = [super init];
    _meta = meta;
    Class cls = _meta->_classInfo.cls;
    
    NSMutableDictionary<NSString *, _ALPropertyJSONMeta *> *allPropertyMetas = [[self allPropertyJSONMetas] mutableCopy];
    if (allPropertyMetas.count) {
        _allPropertyMetas = [allPropertyMetas.allValues copy];
    }
    
    // create mapper
    NSMutableDictionary *mapper            = [NSMutableDictionary dictionary];
    NSMutableArray *keyPathPropertyMetas   = [NSMutableArray array];
    NSMutableArray *multiKeysPropertyMetas = [NSMutableArray array];
    
    if ([cls respondsToSelector:@selector(modelCustomPropertyMapper)]) {
        NSDictionary *customMapper = [(id<YYModel>) cls modelCustomPropertyMapper];
        [customMapper enumerateKeysAndObjectsUsingBlock:^(NSString *propertyName, NSString *mappedToKey, BOOL *stop) {
            _ALPropertyJSONMeta *propertyMeta = allPropertyMetas[propertyName];
            if (!propertyMeta) {
                return;
            }
            [allPropertyMetas removeObjectForKey:propertyName];
            
            if ([mappedToKey isKindOfClass:[NSString class]]) {
                if (mappedToKey.length == 0) {
                    return;
                }
                
                propertyMeta->_mappedToKey   = mappedToKey;
                NSArray<NSString *> *keyPath = [self canonicalKeyPathWith:mappedToKey];
                if (keyPath.count > 1) {
                    propertyMeta->_mappedToKeyPath = keyPath;
                    [keyPathPropertyMetas addObject:propertyMeta];
                }
                propertyMeta->_next = mapper[mappedToKey] ?: nil;
                mapper[mappedToKey] = propertyMeta;
                
            } else if ([mappedToKey isKindOfClass:[NSArray class]]) {
                NSMutableArray *mappedToKeyArray = [NSMutableArray array];
                for (NSString *oneKey in ((NSArray *) mappedToKey)) {
                    if (![oneKey isKindOfClass:[NSString class]]) {
                        continue;
                    }
                    if (oneKey.length == 0) {
                        continue;
                    }
                    
                    NSArray<NSString *> *keyPath = [self canonicalKeyPathWith:oneKey];
                    if (keyPath.count > 1) {
                        [mappedToKeyArray addObject:keyPath];
                    } else {
                        [mappedToKeyArray addObject:oneKey];
                    }
                    
                    if (!propertyMeta->_mappedToKey) {
                        propertyMeta->_mappedToKey     = oneKey;
                        propertyMeta->_mappedToKeyPath = keyPath.count > 1 ? keyPath : nil;
                    }
                }
                if (!propertyMeta->_mappedToKey) {
                    return;
                }
                
                propertyMeta->_mappedToKeyArray = mappedToKeyArray;
                [multiKeysPropertyMetas addObject:propertyMeta];
                
                propertyMeta->_next = mapper[mappedToKey] ?: nil;
                mapper[mappedToKey] = propertyMeta;
            }
        }];
    }
    
    [allPropertyMetas enumerateKeysAndObjectsUsingBlock:^(NSString *name, _ALPropertyJSONMeta *propertyMeta, BOOL *stop) {
        propertyMeta->_mappedToKey = name;
        propertyMeta->_next = mapper[name] ?: nil;
        mapper[name] = propertyMeta;
    }];
    
    if (mapper.count) {
        _mapper = mapper;
    }
    if (keyPathPropertyMetas.count) {
        _keyPathPropertyMetas = keyPathPropertyMetas;
    }
    if (multiKeysPropertyMetas.count) {
        _multiKeysPropertyMetas = multiKeysPropertyMetas;
    }
    
    _hasCustomWillTransformFromDictionary =
        ([cls instancesRespondToSelector:@selector(modelCustomWillTransformFromDictionary:)]);
    _hasCustomTransformFromDictionary =
        ([cls instancesRespondToSelector:@selector(modelCustomTransformFromDictionary:)]);
    _hasCustomTransformToDictionary = ([cls instancesRespondToSelector:@selector(modelCustomTransformToDictionary:)]);
    _hasCustomClassFromDictionary   = ([cls respondsToSelector:@selector(modelCustomClassForDictionary:)]);
    
    return self;
}

- (NSDictionary<NSString *, Class> *)propertyGenericMapper {
    Class cls = _meta->_classInfo.cls;
    if ([cls respondsToSelector:@selector(modelContainerPropertyGenericClass)]) {
        NSDictionary *genericMapper = [(id<YYModel>) cls modelContainerPropertyGenericClass];
        if (genericMapper) {
            NSMutableDictionary *tmp = [NSMutableDictionary dictionary];
            [genericMapper enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                if (![key isKindOfClass:[NSString class]]) {
                    return;
                }
                
                Class meta = object_getClass(obj);
                if (!meta) {
                    return;
                }
                
                if (class_isMetaClass(meta)) {
                    tmp[key] = obj;
                } else if ([obj isKindOfClass:[NSString class]]) {
                    Class cls = NSClassFromString(obj);
                    if (cls) {
                        tmp[key] = cls;
                    }
                }
            }];
            return tmp;
        }
    }
    return nil;
}

- (NSDictionary<NSString *, _ALPropertyJSONMeta *> *)allPropertyJSONMetas {
    NSDictionary<NSString *, Class> *genericMapper = [self propertyGenericMapper];
    NSSet *blacklist =
        [_ALModelHelper model:_meta->_classInfo.cls propertySetWithSelector:@selector(modelPropertyBlacklist)];
    NSSet *whitelist =
        [_ALModelHelper model:_meta->_classInfo.cls propertySetWithSelector:@selector(modelPropertyWhitelist)];

    // Create all property metas.
    NSMutableDictionary<NSString *, _ALPropertyJSONMeta *> *allPropertyMetas = [NSMutableDictionary dictionary];
    for (_ALModelPropertyMeta *propmeta in _meta->_allPropertyMetasDict.allValues) {
        NSString *propname = propmeta->_name;
        if ([blacklist containsObject:propname]) {
            continue;
        }
        if (whitelist && ![whitelist containsObject:propname]) {
            continue;
        }
        
        _ALPropertyJSONMeta *jsonMeta =
        [_ALPropertyJSONMeta metaWithPropertyMeta:propmeta genericClass:genericMapper[propname]];
        if (!jsonMeta) {
            continue;
        }
        if (allPropertyMetas[propname]) {
            continue;
        }
        allPropertyMetas[propname] = jsonMeta;
    }
    return allPropertyMetas;
}

- (NSArray<NSString *> *)canonicalKeyPathWith:(NSString *)keypath {
    NSMutableArray<NSString *> *array = [[keypath componentsSeparatedByString:@"."] mutableCopy];
    NSInteger idx = 0;
    while (idx < array.count) {
        if (array[idx].length == 0) {
            [array removeObjectAtIndex:idx];
        } else {
            idx ++;
        }
    }
    return [array copy];
}

@end
