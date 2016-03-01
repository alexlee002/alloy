//
//  ALModel_Define.m
//  patchwork
//
//  Created by Alex Lee on 2/25/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALModel_Define.h"
#import "YYClassInfo.h"


@implementation ALModel

@end


@implementation ALModel (ClassMetas)

+ (NSDictionary<NSString *, YYClassPropertyInfo *> *)allModelProperties {
    NSMutableDictionary<NSString *, YYClassPropertyInfo *> *allProperties = [NSMutableDictionary dictionary];
    YYClassInfo *info = [YYClassInfo classInfoWithClass:self];
    while (info && info.cls != class_getSuperclass(ALModel.class)) {
        [allProperties addEntriesFromDictionary:info.propertyInfos];
        info = info.superClassInfo;
    }
    return allProperties;
}

+ (NSDictionary<NSString *, YYClassIvarInfo *> *)allModelIvars {
    NSMutableDictionary<NSString *, YYClassIvarInfo *> *allIvars = [NSMutableDictionary dictionary];
    YYClassInfo *info = [YYClassInfo classInfoWithClass:self];
    while (info && info.cls != class_getSuperclass(ALModel.class)) {
        [allIvars addEntriesFromDictionary:info.ivarInfos];
        info = info.superClassInfo;
    }
    return allIvars;
}

+ (NSDictionary<NSString *, YYClassMethodInfo *> *)allModelMethods {
    NSMutableDictionary<NSString *, YYClassMethodInfo *> *allMethods = [NSMutableDictionary dictionary];
    YYClassInfo *info = [YYClassInfo classInfoWithClass:self];
    while (info && info.cls != class_getSuperclass(ALModel.class)) {
        [allMethods addEntriesFromDictionary:info.methodInfos];
        info = info.superClassInfo;
    }
    return allMethods;
}

+ (BOOL)hasModelProperty:(NSString *)propertyName {
    return [self allModelProperties][propertyName] != nil;
}

@end
