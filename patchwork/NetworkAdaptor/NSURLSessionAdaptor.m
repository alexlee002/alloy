//
//  NSURLSessionAdaptor.m
//  patchwork
//
//  Created by Alex Lee on 3/10/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "NSURLSessionAdaptor.h"
#import "ALHTTPRequest.h"
#import "ALHTTPResponse.h"
#import "BlocksKit.h"
#import "NSString+Helper.h"
#import "UtilitiesHeader.h"
#import "ObjcAssociatedObjectHelpers.h"

@interface NSURLSessionAdaptor() <NSURLSessionDelegate>
@end

@implementation NSURLSessionAdaptor {
    NSURLSession     *_session; // IMPORTANT: session retains its delegate. so there is cycle-retain here.
}

SYNTHESIZE_ASC_OBJ(srcRequest, setSrcRequest)


+ (instancetype)adaptorWithSessionConfiguration:(NSURLSessionConfiguration *)config {
    NSURLSessionAdaptor *adaptor = [[self alloc] init];
    NSOperationQueue *queue      = [[NSOperationQueue alloc] init];
    adaptor->_session            = [NSURLSession sessionWithConfiguration:config delegate:adaptor delegateQueue:queue];
    return adaptor;
}

- (void)dealloc {
    ALLogVerbose(@"~~~ DEALLOC: %@ ~~~", self);
}

#pragma mark -
- (BOOL)sendRequest:(__kindof ALHTTPRequest *)request {
    NSURLSessionTask *task = nil;
    NSURLRequest *urlRequest = [self urlRequestTransformFromALRequest:request];
    if (request.type == ALRequestTypeUpload) {
        // TODO: need to support multipart request.
        // if files information are set, using stream upload
        // else if datas are set, using data upload
    } else if (request.type == ALRequestTypeDownload) {
        task = [_session downloadTaskWithRequest:urlRequest];
    } else {
        task = [_session dataTaskWithRequest:urlRequest];
    }
    
    [request setValue:@(task.taskIdentifier) forKey:@"identifier"];
    [self setSrcRequest:request];
    
    [task resume];
    return YES;
}

- (NSURLRequest *)urlRequestTransformFromALRequest:(__kindof ALHTTPRequest *)request {
    NSMutableURLRequest *urlRequest = nil;
    if (request.method == ALHTTPMethodPost) {
        urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:request.url]];
        [request.params bk_each:^(NSString *key, id value) {
            [urlRequest setValue:value forHTTPHeaderField:key];
        }];
    } else {
        NSURL *url  = [NSURL URLWithString:[stringOrEmpty(request.url) urlStringbyAppendingQueryItems:request.params]];
        urlRequest = [NSMutableURLRequest requestWithURL:url];
    }
    urlRequest.HTTPMethod = [request methodName];
    
    [[request headers] bk_each:^(NSString *key, id value) {
        [urlRequest setValue:value forHTTPHeaderField:key];
    }];
    
    return urlRequest;
}

#pragma mark -
@dynamic maxConcurrentRequestCount;
- (void)setMaxConcurrentRequestCount:(NSInteger)maxConcurrentRequestCount {
    ALLogWarn(@"NSURLSession not supported!");
}

- (NSInteger)maxConcurrentRequestCount {
    ALLogWarn(@"NSURLSession not supported!");
    return 0;
}

- (void)fetchRequestsWithCompletion:(void (^)(NSArray<__kindof ALHTTPRequest *> *requests))completion {
    
}

- (void)suspend {

}

- (void)resume {

}

// cancel specified request
- (void)cancelRequestWithIdentifyer:(NSUInteger)identifier {

}

// cancel all request, but the queue is still alive, and able to accept new requests.
- (void)cancellAllRequest {

}

// waiting all requests finished and then release the queue, and can not accept new request again.
- (void)finishRequestsAndInvalidate {

}

// send 'cancel' message to all request and release the queue.
- (void)invalidateAndCancel {

}


#pragma mark - NSURLSession delegates
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    ALLogInfo(@"session: %@ become invalid. Error: %@", _session, error);
    _session = nil;
}

// multipart upload
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
 needNewBodyStream:(void (^)(NSInputStream *__nullable bodyStream))completionHandler {
}

- (void)URLSession:(NSURLSession *)session
                        task:(NSURLSessionTask *)task
             didSendBodyData:(int64_t)bytesSent
              totalBytesSent:(int64_t)totalBytesSent
    totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    
}

@end
