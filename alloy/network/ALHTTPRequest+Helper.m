//
//  ALHTTPRequest+Helper.m
//  patchwork
//
//  Created by Alex Lee on 3/26/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALHTTPRequest+Helper.h"
#import "ALNetwork_config.h"
#import "NSURLSessionAdaptor.h"

@implementation ALHTTPRequest (Helper)

+ (instancetype)requestWithURLString:(NSString *)url
                              method:(ALHTTPMethod)method
                        completion:(ALHTTPCompletionBlock)completion {
    ALHTTPRequest *request = [self requestWithURLString:url];
    request.method = method;
    request.completionBlock = completion;
    return request;
}

+ (instancetype)requestWithURLString:(NSString *)url
                              method:(ALHTTPMethod)method
                  responseModelClass:(Class)modelClass
                          completion:(ALHTTPResponseModelBlock)completion {
    ALHTTPRequest *request = [self requestWithURLString:url];
    request.method = method;
    request.responseModelClass = modelClass;
    request.responseModelBlock = completion;
    return request;
}

- (BOOL)send {
    return [self sendUsingNetworkAdaptor:nil];
}

- (BOOL)sendUsingNetworkAdaptor:(nullable id<ALURLRequestQueueAdaptorProtocol>)adaptor {
    if (adaptor == nil) {
        adaptor = [self defaultAdaptor];
    }
    return [adaptor sendRequest:self];
}

- (id<ALURLRequestQueueAdaptorProtocol>)defaultAdaptor {
    static id<ALURLRequestQueueAdaptorProtocol> DefaultAdaptor = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
#if AL_ENABLE_ASIHTTPREQUEST
        DefaultAdaptor = [[NSClassFromString(@"ASIHTTPRequestQueueAdaptor") alloc] init];
        
#endif
        if (DefaultAdaptor == nil) {
            DefaultAdaptor = [NSURLSessionAdaptor
                adaptorWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        }
    });
    return DefaultAdaptor;
}

@end
