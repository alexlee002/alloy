//
//  ALHTTPRequest+Helper.h
//  patchwork
//
//  Created by Alex Lee on 3/26/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALHTTPRequest.h"
#import "ALURLRequestQueueAdaptorProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface ALHTTPRequest (Helper)

+ (instancetype)requestWithURLString:(NSString *)url
                              method:(ALHTTPMethod)method
                          completion:(ALHTTPCompletionBlock)completion;

+ (instancetype)requestWithURLString:(NSString *)url
                              method:(ALHTTPMethod)method
                  responseModelClass:(Class)modelClass
                          completion:(ALHTTPResponseModelBlock)completion;

- (BOOL)send;
- (BOOL)sendUsingNetworkAdaptor:(nullable id<ALURLRequestQueueAdaptorProtocol>)adaptor;

@end

NS_ASSUME_NONNULL_END
