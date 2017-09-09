//
//  __ALModelMeta+ActiveRecord.h
//  patchwork
//
//  Created by Alex Lee on 22/06/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "__ALModelMeta.h"
#import "ALDBColumnDefine.h"
#import "ALPropertyColumnBindings.h"
#import "ALDBColumnProperty.h"
#import <memory>
#import <list>


@interface _ALModelTableBindings : NSObject {
    @package
    _ALModelMeta *_modelMeta;
    
    std::list<const ALDBColumnProperty> _allColumnProperties;
    
    NSArray<ALPropertyColumnBindings *> *_allColumns; // sorted columns
    NSDictionary<NSString */*columnName*/, ALPropertyColumnBindings *> *_columnsDict;
//    NSDictionary<NSString */*propertyName*/, ALPropertyColumnBindings *> *_columnsMapper;
    
//    NSArray<_ALPropertyColumnBindings *> *_allPropertyBindings;
    NSArray<NSString */*propertyName*/> *_allPrimaryKeys; // property name of primary keys
    NSArray<NSArray<NSString */*propertyName*/> *> *_allUniqueKeys;  // property name of unique keys
    NSArray<NSArray<NSString */*propertyName*/> *> *_allIndexeKeys;  // property name of index keys
}

+ (instancetype)bindingsWithClass:(Class)cls;
+ (instancetype)bindingsWithModelMeta:(_ALModelMeta *)meta;

- (NSString *)columnNameForProperty:(NSString *)propertyName;
@end
