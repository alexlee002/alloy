//
//  NSURLSessionAdaptor.h
//  patchwork
//
//  Created by Alex Lee on 3/10/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALURLRequestQueueAdaptorProtocol.h"

@interface NSURLSessionAdaptor : NSObject <ALURLRequestQueueAdaptorProtocol>

+ (instancetype)adaptorWithSessionConfiguration:(NSURLSessionConfiguration *)config;

@end
