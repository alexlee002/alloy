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

+ (ALDBColumnType)ALDBColumnType;
- (const aldb::SQLValue)al_valueByTransformingToDB;
- (nullable instancetype)al_valueByTransformingFromDBObject:(nullable id)obj;
@end
