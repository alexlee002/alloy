//
//  ALDBValueCoding.h
//  alloy
//
//  Created by Alex Lee on 28/07/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALDBTypeDefs.h"
#import "ALSQLValue.h"

@protocol ALDBValueCoding <NSObject>
// Custom define column type and value coding in specified model define.
// If different SDKs defines the same class's value coding,  there would be conflict.

//+ (ALDBColumnType)al_DBColumnType;
//- (const aldb::SQLValue)al_DBColumnValue;
//+ (nullable instancetype)al_instanctWithColumnValue:(nullable id)obj;
@end
