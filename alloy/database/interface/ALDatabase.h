//
//  ALDatabase.h
//  alloy
//
//  Created by Alex Lee on 02/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALDBHandle.h"

NS_ASSUME_NONNULL_BEGIN

@interface ALDatabase : ALDBHandle

+ (nullable instancetype)databaseWithPath:(NSString *)path;
+ (nullable instancetype)databaseWithPath:(NSString *)path keepAlive:(BOOL)keepAlive;

- (void)keepAlive:(BOOL)yesOrNo;
- (void)close;

@end

NS_ASSUME_NONNULL_END
