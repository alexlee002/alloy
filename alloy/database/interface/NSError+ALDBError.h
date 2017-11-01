//
//  NSError+ALDBError.h
//  alloy
//
//  Created by Alex Lee on 03/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "error.hpp"

@interface NSError (ALDBError)

+ (instancetype)errorWithALDBError:(const aldb::Error &)error;

@end
