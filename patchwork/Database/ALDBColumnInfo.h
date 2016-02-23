//
//  ALDBColumnInfo.h
//  patchwork
//
//  Created by Alex Lee on 2/19/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ALDBColumnInfo: NSObject
@property(nonatomic, copy)              NSString *name;
@property(nonatomic, copy)              NSString *dataType;
@property(nonatomic, copy, nullable)    NSString *extra;
@end

NS_ASSUME_NONNULL_END