//
//  ASIHTTPRequestQueueAdaptor.m
//  patchwork
//
//  Created by Alex Lee on 3/10/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ASIHTTPRequestQueueAdaptor.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "UtilitiesHeader.h"
#import "ALHTTPResponse.h"
#import "ALHTTPRequest.h"
#import "BlocksKit.h"
#import "NSString+Helper.h"
#import "NSArray+ArrayExtensions.h"

@interface ASIHTTPRequestQueueAdaptor() <ASIHTTPRequestDelegate, ASIProgressDelegate>

@end

#define requestDesc(srcReq)      [NSString stringWithFormat:@"%@ (id:%@)", (srcReq).class, @((srcReq).identifier)]
#define sourceRequestOf(asi)     [_requestDict[@((asi).tag)] firstObject]


@implementation ASIHTTPRequestQueueAdaptor {
    // NSArray: @[ALHTTPRequest, ASIHTTPRequest]
    NSMutableDictionary<NSNumber *, NSArray *> *_requestDict;
    NSOperationQueue                           *_requestQueue;
    
    BOOL  _invalidated;
}

@dynamic maxConcurrentRequestCount;
@synthesize delegate;

- (instancetype)init {
    self = [super init];
    if (self) {
        _requestDict  = [NSMutableDictionary dictionary];
        _requestQueue = [[NSOperationQueue alloc] init];
        _requestQueue.maxConcurrentOperationCount = 10;
    }
    return self;
}

- (void)dealloc {
    ALLogVerbose(@"~~~ DEALLOC: %@ ~~~", self);
    
    [_requestDict.allValues bk_each:^(NSArray *pairs) {
        ASIHTTPRequest *request = [pairs objectAtIndexSafely:1];
        if ([request isKindOfClass:[ASIHTTPRequest class]]) {
            [request clearDelegatesAndCancel];
        }
    }];
}

#pragma mark -
- (BOOL)sendRequest:(ALHTTPRequest *)request {
    if (_invalidated) {
        NSAssert(NO, @"%@ invalidated! new request can not be accepted anymore.", self);
        return NO;
    }
    ASIHTTPRequest *asiRequest = [self transformFromALRequest:request];
    _requestDict[@(asiRequest.tag)] = @[ request, asiRequest ];
    //[asiRequest startAsynchronous];
    [_requestQueue addOperation:asiRequest];
    [request setValue:@(ALHTTPRequestStateRunning) forKey:keypath(request.state)];
    return YES;
}

- (ASIHTTPRequest *)transformFromALRequest:(__kindof ALHTTPRequest *)request {
    ASIHTTPRequest *asiRequest = nil;
    if (request.method == ALHTTPMethodPost) {
        asiRequest = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:request.url]];
        [request.params bk_each:^(NSString *key, id value) {
            [(ASIFormDataRequest *) asiRequest setPostValue:value forKey:key];
        }];

        if (request.type == ALRequestTypeUpload) {
            [self buildUploadRequest:&asiRequest with:request];
        }
    } else {
        if (request.type == ALRequestTypeDownload) {
            [self buildDownloadRequest:&asiRequest with:request];
        } else {
            NSURL *url = [NSURL URLWithString:[stringOrEmpty(request.url) stringbyAppendingQueryItems:request.params]];
            asiRequest = [ASIHTTPRequest requestWithURL:url];
        }
    }
    asiRequest.requestMethod = [request methodName];

    [[request headers] bk_each:^(NSString *key, id value) {
        [asiRequest addRequestHeader:key value:value];
    }];

    if (!isEmptyString(request.userAgent)) {
        asiRequest.userAgentString = request.userAgent;
    }

    asiRequest.delegate                      = self;
    asiRequest.useCookiePersistence          = NO;
    asiRequest.timeOutSeconds                = request.maximumnConnectionTimeout;
    asiRequest.tag                           = [self uniqueRequestId];
    [request setValue:@(asiRequest.tag)              forKey:keypath(request.identifier)];
    [request setValue:@(ALHTTPRequestStateSuspended) forKey:keypath(request.state)];
    
    return asiRequest;
}

- (void)buildUploadRequest:(ASIHTTPRequest **)asiRequest with:(__kindof ALHTTPRequest *)request {
    [request.uploadParams bk_each:^(NSString *key, id fileObj) {
        if ([fileObj isKindOfClass:[NSDictionary class]]) {
            [(ASIFormDataRequest *) (*asiRequest) setData:fileObj[@"data"]
                                             withFileName:fileObj[@"filename"]
                                           andContentType:@"contenttype"
                                                   forKey:key];
        } else {
            [(ASIFormDataRequest *) (*asiRequest) setData:fileObj forKey:key];
        }
    }];
    (*asiRequest).uploadProgressDelegate = self;
    (*asiRequest).showAccurateProgress   = YES;
}

- (void)buildDownloadRequest:(ASIHTTPRequest **)asiRequest with:(__kindof ALHTTPRequest *)request {
    NSURL *url  = [NSURL URLWithString:[stringOrEmpty(request.url) stringbyAppendingQueryItems:request.params]];
    *asiRequest = [ASIHTTPRequest requestWithURL:url];
    (*asiRequest).allowCompressedResponse     = NO;
    (*asiRequest).allowResumeForFileDownloads = YES;
    [(*asiRequest) setDownloadDestinationPath:[request downlFilePath]];
    [(*asiRequest) setTemporaryFileDownloadPath:request.temporaryDownloadFilePath];
    (*asiRequest).downloadProgressDelegate = self;
    (*asiRequest).showAccurateProgress     = YES;
    if ([(*asiRequest) shouldResetDownloadProgress]) {
        [(*asiRequest) setShouldResetDownloadProgress:NO];
    }
}



- (NSUInteger)uniqueRequestId {
    static dispatch_semaphore_t lock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lock = dispatch_semaphore_create(1);
    });
    
    static NSUInteger kIdentifier;
    NSUInteger nextId;
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    nextId = ++kIdentifier;
    dispatch_semaphore_signal(lock);
    return nextId;
}

#pragma mark -
- (void)setMaxConcurrentRequestCount:(NSInteger)maxConcurrentRequestCount {
    _requestQueue.maxConcurrentOperationCount = maxConcurrentRequestCount;
}

- (NSInteger)maxConcurrentRequestCount {
    return _requestQueue.maxConcurrentOperationCount;
}

- (void)fetchRequestsWithCompletion:(void (^)(NSArray<__kindof ALHTTPRequest *> * _Nonnull))completion {
    if (completion == nil) {
        return;
    }
    completion([[_requestDict.allValues bk_map:^ALHTTPRequest *(NSArray *pairs) {
        return pairs.firstObject;
    }] bk_select:^BOOL(id obj) {
        return [obj isKindOfClass:[ALHTTPRequest class]];
    }]);
}

- (void)cancelRequestWithIdentifyer:(NSUInteger)identifier {
    ALHTTPRequest  *srcReq = [_requestDict[@(identifier)] firstObject];
    ASIHTTPRequest *asiReq = [_requestDict[@(identifier)] objectAtIndexSafely:1];
    
    [srcReq setValue:@(ALHTTPRequestStateCancelled) forKey:keypath(srcReq.state)];
    [asiReq cancel];
}

- (void)cancellAllRequest {
    [_requestDict.allKeys bk_each:^(NSNumber *identifier) {
        [self cancelRequestWithIdentifyer:identifier.unsignedIntegerValue];
    }];
}

- (void)suspend {
    _requestQueue.suspended = YES;
}

- (void)resume {
    _requestQueue.suspended = NO;
}

- (void)finishRequestsAndInvalidate {
    _invalidated = YES;
}

- (void)invalidateAndCancel {
    _invalidated = YES;
    [self cancellAllRequest];
}

#pragma mark - ASIHTTPRequest delegates
- (void)requestStarted:(ASIHTTPRequest *)request {
    ALHTTPRequest *srcReq = sourceRequestOf(request);
    ALLogVerbose(@"\nsending request: %@", srcReq);
    if (srcReq.startBlock != nil) {
        srcReq.startBlock();
    }
}

- (void)request:(ASIHTTPRequest *)request didReceiveResponseHeaders:(NSDictionary *)responseHeaders {
    ALHTTPRequest *srcReq = sourceRequestOf(request);
    if (srcReq.headersRespondsBlock != nil) {
        srcReq.headersRespondsBlock(responseHeaders);
    }
}

- (void)requestFinished:(ASIHTTPRequest *)request {
    ALHTTPRequest *srcReq = sourceRequestOf(request);
    ALLogVerbose(@"\nrequest: %@\nresponse: %@", requestDesc(srcReq), request.responseString);
    
    [srcReq setValue:@(ALHTTPRequestStateCompleted) forKey:keypath(srcReq.state)];
    if (srcReq.completionBlock != nil) {
        srcReq.completionBlock([ALHTTPResponse responseWithASIHttpRequest:request], nil);
    }
    
    CheckMemoryLeak(request);
    [_requestDict removeObjectForKey:@(request.tag)];
    if (_invalidated && _requestDict.count == 0 && [self.delegate respondsToSelector:@selector(queueAdaptorDidBecomeInvalid:)]) {
        [self.delegate queueAdaptorDidBecomeInvalid:self];
    }
    
}

- (void)requestFailed:(ASIHTTPRequest *)request {
    ALHTTPRequest *srcReq = sourceRequestOf(request);
    ALLogVerbose(@"\nrequest: %@\nerror: %@", requestDesc(srcReq), request.responseString);
    
    [srcReq setValue:@(ALHTTPRequestStateCompleted) forKey:keypath(srcReq.state)];
    if (srcReq.completionBlock != nil) {
        srcReq.completionBlock([ALHTTPResponse responseWithASIHttpRequest:request], request.error);
    }
    [_requestDict removeObjectForKey:@(request.tag)];
    if (_invalidated && _requestDict.count == 0 && [self.delegate respondsToSelector:@selector(queueAdaptorDidBecomeInvalid:)]) {
        [self.delegate queueAdaptorDidBecomeInvalid:self];
    }
    CheckMemoryLeak(request);
}

#pragma mark - ASIProgressDelegate

- (void)request:(ASIHTTPRequest *)request incrementDownloadSizeBy:(long long)newLength {
    ALHTTPRequest *srcReq = sourceRequestOf(request);
    if (srcReq.progressBlock) {
        srcReq.progressBlock(0, [request partialDownloadSize], newLength);
    }
}

- (void)request:(ASIHTTPRequest *)request didReceiveBytes:(long long)bytes {
    ALHTTPRequest *srcReq = sourceRequestOf(request);
    if (srcReq.progressBlock) {
        srcReq.progressBlock(bytes, [request partialDownloadSize],
                             [request totalBytesRead] + [request partialDownloadSize]);
    }
}

- (void)request:(ASIHTTPRequest *)request didSendBytes:(long long)bytes {
    ALHTTPRequest *srcReq = sourceRequestOf(request);
    if (srcReq.progressBlock) {
        srcReq.progressBlock(bytes, [request totalBytesSent], [request postLength]);
    }
}


//----
- (void)request:(ASIHTTPRequest *)request willRedirectToURL:(NSURL *)newURL {
    ALHTTPRequest *srcReq = sourceRequestOf(request);
    ALLogVerbose(@"\nrequest: %@ will redirect to: %@", requestDesc(srcReq), newURL);
    [request redirectToURL:newURL];
    [srcReq setValue:newURL forKey:keypath(srcReq.currentURL)];
}

@end
