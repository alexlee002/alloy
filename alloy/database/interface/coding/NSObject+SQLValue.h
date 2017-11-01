//
//  NSObject+SQLValue.h
//  alloy
//
//  Created by Alex Lee on 02/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sql_value.hpp"

@interface NSObject (SQLValue)

- (aldb::SQLValue)al_SQLValue;

@end
