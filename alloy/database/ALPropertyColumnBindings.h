//
//  ALPropertyColumnBindings.h
//  alloy
//
//  Created by Alex Lee on 22/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YYClassInfo.h"
#import "ALDBColumnDefine.h"

@interface ALPropertyColumnBindings : NSObject

- (nullable YYClassPropertyInfo *)propertyInfo;
- (const ALDBColumnDefine &)columnDefine;
- (nullable NSString *)columnName;
- (nullable NSString *)propertyName;

- (nullable SEL)customPropertyValueSetter; // from ResultSet
- (nullable SEL)customPropertyValueGetter; // to Column Value

@end
