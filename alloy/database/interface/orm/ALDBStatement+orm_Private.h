//
//  ALDBStatement+orm_Private.h
//  alloy
//
//  Created by Alex Lee on 11/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDBStatement+orm.h"

@class ALModelSelect;
@interface ALDBStatement (orm_Private)
@property(nonatomic, nullable)  ALModelSelect   *modelSelect;
@end
