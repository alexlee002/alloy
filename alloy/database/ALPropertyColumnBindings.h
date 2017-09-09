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

- (YYClassPropertyInfo *)propertyInfo;
- (const ALDBColumnDefine &)columnDefine;
- (NSString *)columnName;
- (NSString *)propertyName;

- (SEL)customPropertyValueFromColumnTransformer;
- (SEL)customPropertyValueToColumnTransformer;

@end
