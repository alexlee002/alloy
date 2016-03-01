//
//  ALModel_Define.h
//  patchwork
//
//  Created by Alex Lee on 2/25/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ALModel : NSObject

@end


@class YYClassPropertyInfo;
@class YYClassIvarInfo;
@class YYClassMethodInfo;
@interface ALModel (ClassMetas)
+ (NSDictionary<NSString *, YYClassPropertyInfo *> *)allModelProperties;
+ (NSDictionary<NSString *, YYClassIvarInfo *> *)allModelIvars;
+ (NSDictionary<NSString *, YYClassMethodInfo *> *)allModelMethods;

+ (BOOL)hasModelProperty:(NSString *)propertyName;

@end

NS_ASSUME_NONNULL_END
