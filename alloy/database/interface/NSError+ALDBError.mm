//
//  NSError+ALDBError.m
//  alloy
//
//  Created by Alex Lee on 03/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "NSError+ALDBError.h"

@implementation NSError (ALDBError)

+ (instancetype)errorWithALDBError:(const aldb::Error &)error {
    return [NSError errorWithDomain:@(error.domain.c_str())
                               code:error.code
                           userInfo:@{
                               NSLocalizedDescriptionKey : @(error.message.c_str())
                           }];
}

@end
