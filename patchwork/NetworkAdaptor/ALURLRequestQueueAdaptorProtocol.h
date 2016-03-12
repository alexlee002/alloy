//
//  ALURLRequestQueueAdaptorProtocol.h
//  patchwork
//
//  Created by Alex Lee on 3/10/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ALURLRequestQueueAdaptorProtocol;
@protocol ALURLRequestQueueAdaptorDelegate <NSObject>

- (void)queueAdaptorDidBecomeInvalid:(id<ALURLRequestQueueAdaptorProtocol>)adaptor;

@end

@class ALHTTPRequest;
@protocol ALURLRequestQueueAdaptorProtocol <NSObject>

@property(weak) id<ALURLRequestQueueAdaptorDelegate> delegate;
// currently not supports NSURLSession
@property                 NSInteger maxConcurrentRequestCount;

- (void)fetchRequestsWithCompletion:(void (^)(NSArray<__kindof ALHTTPRequest *> *requests))completion;
- (BOOL)sendRequest:(ALHTTPRequest *)request;

// currently not supports NSURLSession
- (void)suspend;
// currently not supports NSURLSession
- (void)resume;

// cancel specified request
- (void)cancelRequestWithIdentifyer:(NSUInteger)identifier;
// cancel all request, but the queue is still alive, and able to accept new requests.
- (void)cancellAllRequest;
// waiting all requests finished and then release the queue, and can not accept new request again.
- (void)finishRequestsAndInvalidate;
// send 'cancel' message to all request and release the queue.
- (void)invalidateAndCancel;

@end

NS_ASSUME_NONNULL_END
