//
//  __ALPropertyColumnBindings+private.h
//  alloy
//
//  Created by Alex Lee on 29/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALPropertyColumnBindings.h"
#import "__ALModelMeta.h"

@interface ALPropertyColumnBindings () {
  @package
    Class                                _cls;
    _ALModelPropertyMeta                *_propertyMeta;
    std::shared_ptr<ALDBColumnDefine>    _columnDef;
    NSString                            *_colName;
    
    SEL _customSetter;
    SEL _customGetter;
}

+ (instancetype)bindingWithModelMeta:(_ALModelMeta *)modelMeta
                        propertyMeta:(_ALModelPropertyMeta *)propertyMeta
                              column:(NSString *)columnName;
@end
