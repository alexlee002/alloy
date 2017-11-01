//
//  ALDBColumnBinding_Private.h
//  alloy
//
//  Created by Alex Lee on 08/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDBColumnBinding.h"
#import "_ALModelMeta.h"

@interface ALDBColumnBinding () {
  @package
    Class _cls;
    _ALModelPropertyMeta *_propertyMeta;
    std::shared_ptr<aldb::ColumnDef> _columnDef;
    NSString *_columnName;
    ALDBColumnType _columnType;

    SEL _customSetter;
    SEL _customGetter;
}

+ (instancetype)bindingWithModelMeta:(_ALModelMeta *)modelMeta
                        propertyMeta:(_ALModelPropertyMeta *)propertyMeta
                              column:(NSString *)columnName;
@end
