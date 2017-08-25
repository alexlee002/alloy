//
//  __ALModelMeta+ActiveRecord.h
//  patchwork
//
//  Created by Alex Lee on 22/06/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "__ALModelMeta.h"
#import "ALDBColumnDefine.h"
#import <memory>

@interface _ALPropertyColumnBindings : NSObject {
    @package
    _ALModelPropertyMeta    *_propertyMeta;
    
    std::shared_ptr<ALDBColumnDefine> _column;
    NSString *_columnName;
    SEL _customPropertyToColumnValueTransformer;
    SEL _customPropertyValueFromColumnTransformer;
}

+ (instancetype)bindingWithPropertyMeta:(_ALModelPropertyMeta *)meta column:(NSString *)columnName;
@end

@interface _ALModelTableBindings : NSObject {
    @package
    _ALModelMeta *_modelMeta;
    
    NSDictionary<NSString */*columnName*/, _ALPropertyColumnBindings *> *_columnMapper;
    
//    NSArray<_ALPropertyColumnBindings *> *_allPropertyBindings;
    NSArray<NSString *> *_allPrimaryKeys; // property name of primary keys
    NSArray<NSArray<NSString *> *> *_allUniqueKeys;  // property name of unique keys
    NSArray<NSArray<NSString *> *> *_allIndexeKeys;  // property name of index keys
}

+ (instancetype)bindingsWithClass:(Class)cls;
+ (instancetype)bindingsWithModelMeta:(_ALModelMeta *)meta;
@end
