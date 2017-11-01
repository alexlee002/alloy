//
//  ALDBColumnBinding.h
//  alloy
//
//  Created by Alex Lee on 07/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YYClassInfo.h"
#import "column_def.hpp"
#import "ALDBTypeDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface ALDBColumnBinding : NSObject

- (nullable YYClassPropertyInfo *)propertyInfo;
- (const std::shared_ptr<aldb::ColumnDef> &)columnDefine;
- (nullable NSString *)columnName;
- (nullable NSString *)propertyName;
- (nullable Class)modelClass;
- (ALDBColumnType)columnType;

- (nullable SEL)customPropertyValueSetter; // from ResultSet
- (nullable SEL)customPropertyValueGetter; // to Column Value

@end

NS_ASSUME_NONNULL_END
