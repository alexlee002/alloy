//
//  ALDatabase.h
//  alloy
//
//  Created by Alex Lee on 27/07/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN
@interface ALDatabase : NSObject

@property(nonatomic, readonly, copy) NSString *path;

+ (nullable instancetype)databaseWithPath:(NSString *)path keepAlive:(BOOL)keepAlive;
- (void)close;

@end
NS_ASSUME_NONNULL_END
