//
//  NSURLSessionAdaptor.h
//  patchwork
//
//  Created by Alex Lee on 3/10/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALURLRequestQueueProtocol.h"

@interface NSURLSessionAdaptor : NSObject <ALURLRequestQueueProtocol>

+ (instancetype)adaptorWithSessionConfiguration:(NSURLSessionConfiguration *)config;

@end
