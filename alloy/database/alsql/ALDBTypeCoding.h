//
//  ALDBTypeCoding.h
//  alloy
//
//  Created by Alex Lee on 05/08/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALDBTypeDefs.h"

@interface ALDBTypeCoding : NSObject

+ (ALDBColumnType)columnTypeForObjCType:(const char *)objcTypeEncode;
@end
