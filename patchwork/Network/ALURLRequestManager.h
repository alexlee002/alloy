//
//  ALURLRequestManager.h
//  patchwork
//
//  Created by Alex Lee on 3/4/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALNetwork_config.h"

#if AL_ENABLE_ASIHTTPREQUEST
#import "ASIHTTPRequestAdaptor.h"
#endif

#if AL_ENABLE_NSURLSESSION
#endif

#import "ALHTTPRequest.h"

NS_ASSUME_NONNULL_BEGIN
@protocol ALURLRequestManagerDelegate <NSObject>

- (Class)adaptorClassForRequest:(ALHTTPRequest *)request;

@end

@interface ALURLRequestManager : NSObject

#if AL_ENABLE_NSURLSESSION
+ (instancetype)managerWithDelegate:(id<ALURLRequestManagerDelegate>)delegate
               sessionConfiguration:(NSURLSessionConfiguration *)configuration;
#endif

+ (instancetype)managerWithDelegate:(id<ALURLRequestManagerDelegate>)delegate;

- (void)fetchRequestsWithCompletion:(NSArray<ALHTTPRequest *> *)completion;

- (void)sendRequest:(ALHTTPRequest *)request;
- (void)cancelRequestWithIdentifyer:(NSUInteger)identifier;

@end

NS_ASSUME_NONNULL_END
