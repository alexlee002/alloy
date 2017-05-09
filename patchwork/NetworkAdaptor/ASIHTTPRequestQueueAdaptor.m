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
#import "ALUtilitiesHeader.h"
#import "ALHTTPResponse.h"
#import "ALHTTPRequest.h"
#import "BlocksKit.h"
#import "AL_URLHelper.h"
#import "NSString+ALHelper.h"
#import "NSArray+ArrayExtensions.h"
#import "AL_JSON.h"
#import "NSObject+YYModel.h"
#import "ALLogger.h"


@interface ALHTTPResponse (ASIHTTPRequestAdaptor)
+ (instancetype)responseWithASIHttpRequest:(ASIHTTPRequest *)request;
@end

@implementation ALHTTPResponse (ASIHTTPRequestAdaptor)

+ (instancetype)responseWithASIHttpRequest:(ASIHTTPRequest *)request {
    NSHTTPURLResponse *nsResponse = [[NSHTTPURLResponse alloc]
         initWithURL:request.url
          statusCode:request.responseStatusCode
         HTTPVersion:((__bridge NSString *) (request.useHTTPVersionOne ? kCFHTTPVersion1_0 : kCFHTTPVersion1_1))
        headerFields:request.responseHeaders];
    return [self responseWithNSURLResponse:nsResponse responseData:request.responseData];
}

@end

#pragma mark -
@interface ASIHTTPRequest (ALDebugging)

@end

@implementation ASIHTTPRequest (ALDebugging)

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"%@; tag:%ld", self.description, (long)self.tag];
}

@end


#pragma mark -
@interface ASIHTTPRequestQueueAdaptor() <ASIHTTPRequestDelegate, ASIProgressDelegate>

@end

#define sourceRequestOf(asi)     [_requestDict[@((asi).tag)] firstObject]


@implementation ASIHTTPRequestQueueAdaptor {
    // NSArray: @[ALHTTPRequest, ASIHTTPRequest]
    NSMutableDictionary<NSNumber *, NSArray *> *_requestDict;
    NSOperationQueue                           *_requestQueue;
    
    BOOL  _invalidated;
    dispatch_semaphore_t _requestDictLock;
}

@dynamic maxConcurrentRequestCount;
@synthesize delegate;

- (instancetype)init {
    self = [super init];
    if (self) {
        _requestDict  = [NSMutableDictionary dictionary];
        _requestQueue = [[NSOperationQueue alloc] init];
        _requestQueue.maxConcurrentOperationCount = 10;
        _requestDictLock = dispatch_semaphore_create(1);
    }
    return self;
}

- (void)dealloc {
    ALLogVerbose(@"~~~ DEALLOC: %@ ~~~", self);
    
    [_requestDict.allValues bk_each:^(NSArray *pairs) {
        ASIHTTPRequest *request = [pairs al_objectAtIndexSafely:1];
        if ([request isKindOfClass:[ASIHTTPRequest class]]) {
            [request cancel];
        }
    }];
}

#pragma mark -
- (BOOL)sendRequest:(ALHTTPRequest *)request {
    al_guard_or_return(!_invalidated, NO);
    
    ASIHTTPRequest *asiRequest = [self transformFromALRequest:request];
    
    dispatch_semaphore_wait(_requestDictLock, DISPATCH_TIME_FOREVER);
    _requestDict[@(asiRequest.tag)] = @[ request, asiRequest ];
    dispatch_semaphore_signal(_requestDictLock);
    
    [_requestQueue addOperation:asiRequest];
    [request setValue:@(ALHTTPRequestStateRunning) forKey:al_keypath(request.state)];
    return YES;
}

- (ASIHTTPRequest *)transformFromALRequest:(__kindof ALHTTPRequest *)request {
    ASIHTTPRequest *asiRequest = nil;
    
    if (request.type == ALRequestTypeNotInitialized) {
        request.type = [request autoDetectRequestType];
    }
    if (request.uploadParams.count > 0 && request.method == ALHTTPMethodGet) {
        request.method = ALHTTPMethodPost;
    }

    if (request.type == ALRequestTypeUpload) {
        [self buildUploadRequest:&asiRequest with:request];
    } else if (request.type == ALRequestTypeDownload) {
        [self buildDownloadRequest:&asiRequest with:request];
    } else if (request.method == ALHTTPMethodPost) {
        asiRequest = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:request.url]];
        NSData *postBody =ALCastToTypeOrNil([request postBody], NSData);
        if (postBody != nil) {
            asiRequest.postBody = [postBody mutableCopy];
        } else {
            [request.params bk_each:^(NSString *key, id value) {
                [(ASIFormDataRequest *) asiRequest setPostValue:URLParamStringify(value) forKey:URLParamStringify(key)];
            }];
        }
    } else {
        NSURL *url = [[NSURL URLWithString:al_stringOrEmpty(request.url)] URLBySettingQueryParamsOfDictionary:request.params];
        asiRequest = [ASIHTTPRequest requestWithURL:url];
    }

    asiRequest.requestMethod = [request methodName];

    [[request headers] bk_each:^(NSString *key, id value) {
        [asiRequest addRequestHeader:key value:value];
    }];

    if (!al_isEmptyString(request.userAgent)) {
        asiRequest.userAgentString = request.userAgent;
    }

    asiRequest.delegate                      = self;
    asiRequest.useCookiePersistence          = NO;
    asiRequest.timeOutSeconds                = request.maximumnConnectionTimeout;
    asiRequest.tag                           = request.identifier;
    [request setValue:@(ALHTTPRequestStateSuspended) forKey:al_keypath(request.state)];
    
    return asiRequest;
}

- (void)buildUploadRequest:(ASIHTTPRequest **)asiRequest with:(__kindof ALHTTPRequest *)request {
    NSParameterAssert(asiRequest != NULL);
    
    NSURL *url  = [[NSURL URLWithString:al_stringOrEmpty(request.url)] URLBySettingQueryParamsOfDictionary:request.params];
    if (request.method == ALHTTPMethodPut) {
        *asiRequest = [ASIHTTPRequest requestWithURL:url];
        (*asiRequest).shouldStreamPostDataFromDisk = YES;
        [request.uploadParams bk_each:^(NSString *key, id fileObj) {
            NSData *data = ALCastToTypeOrNil(fileObj, NSData);
            if (data != nil) {
                [(*asiRequest) appendPostData:data];
            } else {
                //TODO: setPostBodyFilePath: ?
            }
        }];
    } else {
        // default method is Post
        *asiRequest = [ASIFormDataRequest requestWithURL:url];
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
    }
    
    (*asiRequest).uploadProgressDelegate = self;
    (*asiRequest).showAccurateProgress   = YES;
}

- (void)buildDownloadRequest:(ASIHTTPRequest **)asiRequest with:(__kindof ALHTTPRequest *)request {
    NSParameterAssert(asiRequest != NULL);
    
    NSURL *url  = [[NSURL URLWithString:al_stringOrEmpty(request.url) ] URLBySettingQueryParamsOfDictionary:request.params];
    *asiRequest = [ASIHTTPRequest requestWithURL:url];
    (*asiRequest).allowCompressedResponse     = NO;
    (*asiRequest).allowResumeForFileDownloads = YES;
    [(*asiRequest) setDownloadDestinationPath:[request downloadFilePath]];
    [(*asiRequest) setTemporaryFileDownloadPath:request.temporaryDownloadFilePath];
    (*asiRequest).downloadProgressDelegate = self;
    (*asiRequest).showAccurateProgress     = YES;
    if ([(*asiRequest) shouldResetDownloadProgress]) {
        [(*asiRequest) setShouldResetDownloadProgress:NO];
    }
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
    [self cancelRequestWithIdentifyer:identifier contextHandler:nil];
}

- (void)cancelRequestWithIdentifyer:(NSUInteger)identifier contextHandler:(void (^_Nullable)(id _Nullable))handler {
    ALHTTPRequest  *srcReq = [_requestDict[@(identifier)] firstObject];
    ASIHTTPRequest *asiReq = [_requestDict[@(identifier)] al_objectAtIndexSafely:1];
    
    [srcReq setValue:@(ALHTTPRequestStateCancelled) forKey:al_keypath(srcReq.state)];
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
    dispatch_semaphore_wait(_requestDictLock, DISPATCH_TIME_FOREVER);
    ALHTTPRequest *srcReq = sourceRequestOf(request);
    dispatch_semaphore_signal(_requestDictLock);

    [srcReq requestDidStart];
}

- (void)request:(ASIHTTPRequest *)request didReceiveResponseHeaders:(NSDictionary *)responseHeaders {
    dispatch_semaphore_wait(_requestDictLock, DISPATCH_TIME_FOREVER);
    ALHTTPRequest *srcReq = sourceRequestOf(request);
    dispatch_semaphore_signal(_requestDictLock);
    
    [srcReq requestDidReceiveResponse:request.responseStatusCode headers:responseHeaders];
}

- (void)requestFinished:(ASIHTTPRequest *)request {
    dispatch_semaphore_wait(_requestDictLock, DISPATCH_TIME_FOREVER);
    ALHTTPRequest *srcReq = sourceRequestOf(request);
    dispatch_semaphore_signal(_requestDictLock);
    
    [srcReq requestDidSucceedWithResponse:[ALHTTPResponse responseWithASIHttpRequest:request]];

    ALTrackMemoryLeak(request);
    ALLogVerbose(@"srcRequest:%@", srcReq.class);
    
    dispatch_semaphore_wait(_requestDictLock, DISPATCH_TIME_FOREVER);
    [_requestDict removeObjectForKey:@(request.tag)];
    dispatch_semaphore_signal(_requestDictLock);
    
    ALCheckMemoryLeak(request);
    
    if (_invalidated && _requestDict.count == 0 &&
        [self.delegate respondsToSelector:@selector(queueAdaptorDidBecomeInvalid:)]) {
        [self.delegate queueAdaptorDidBecomeInvalid:self];
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request {
    dispatch_semaphore_wait(_requestDictLock, DISPATCH_TIME_FOREVER);
    ALHTTPRequest *srcReq = sourceRequestOf(request);
    dispatch_semaphore_signal(_requestDictLock);
    
    [srcReq requestDidFailWithResponse:[ALHTTPResponse responseWithASIHttpRequest:request]
                                 error:[self NSURLErrorTransformingFromASIError:request.error]];
    
    ALTrackMemoryLeak(request);
    ALLogVerbose(@"srcRequest:%@", srcReq.class);
    
    dispatch_semaphore_wait(_requestDictLock, DISPATCH_TIME_FOREVER);
    [_requestDict removeObjectForKey:@(request.tag)];
    dispatch_semaphore_signal(_requestDictLock);
    
    ALCheckMemoryLeak(request);

    if (_invalidated && _requestDict.count == 0 &&
        [self.delegate respondsToSelector:@selector(queueAdaptorDidBecomeInvalid:)]) {
        [self.delegate queueAdaptorDidBecomeInvalid:self];
    }
}

- (NSError *)NSURLErrorTransformingFromASIError:(NSError *)error {
    NSDictionary *userinfo = @{NSUnderlyingErrorKey: error};
    switch (error.code) {
        case ASIConnectionFailureErrorType:
            return [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCannotConnectToHost userInfo:userinfo];
        case ASIRequestTimedOutErrorType:
            return [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:userinfo];
        case ASIAuthenticationErrorType:
            return [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUserAuthenticationRequired userInfo:userinfo];
        case ASIRequestCancelledErrorType:
            return [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:userinfo];
        case ASIUnableToCreateRequestErrorType:
            return [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:userinfo];
        case ASIInternalErrorWhileBuildingRequestType:
            return [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUnknown userInfo:userinfo];
        case ASIInternalErrorWhileApplyingCredentialsType:
            return [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUserAuthenticationRequired userInfo:userinfo];
        case ASIFileManagementError:
            return [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUnknown userInfo:userinfo];
        case ASITooMuchRedirectionErrorType:
            return [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorHTTPTooManyRedirects userInfo:userinfo];
        case ASIUnhandledExceptionError:
            return [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUnknown userInfo:userinfo];
        case ASICompressionError:
            return [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUnknown userInfo:userinfo];
        default:
            return [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUnknown userInfo:userinfo];
    }
}

#pragma mark - ASIProgressDelegate

- (void)request:(ASIHTTPRequest *)request incrementDownloadSizeBy:(long long)newLength {
    dispatch_semaphore_wait(_requestDictLock, DISPATCH_TIME_FOREVER);
    ALHTTPRequest *srcReq = sourceRequestOf(request);
    dispatch_semaphore_signal(_requestDictLock);
    
    [srcReq requestDidReceiveBytes:0
                 totalBytesReceived:[request partialDownloadSize]
        totalBytesExpectedToReceive:newLength];
}

- (void)request:(ASIHTTPRequest *)request didReceiveBytes:(long long)bytes {
    dispatch_semaphore_wait(_requestDictLock, DISPATCH_TIME_FOREVER);
    ALHTTPRequest *srcReq = sourceRequestOf(request);
    dispatch_semaphore_signal(_requestDictLock);
    
    [srcReq requestDidReceiveBytes:bytes
                 totalBytesReceived:[request totalBytesRead]
        totalBytesExpectedToReceive:request.contentLength];
}

- (void)request:(ASIHTTPRequest *)request didSendBytes:(long long)bytes {
    dispatch_semaphore_wait(_requestDictLock, DISPATCH_TIME_FOREVER);
    ALHTTPRequest *srcReq = sourceRequestOf(request);
    dispatch_semaphore_signal(_requestDictLock);
    
    [srcReq requestDidSendBytes:bytes
                  totalBytesSent:[request totalBytesSent]
        totalBytesExpectedToSend:[request postLength]];
}

//----
- (void)request:(ASIHTTPRequest *)request willRedirectToURL:(NSURL *)newURL {
    dispatch_semaphore_wait(_requestDictLock, DISPATCH_TIME_FOREVER);
    ALHTTPRequest *srcReq = sourceRequestOf(request);
    dispatch_semaphore_signal(_requestDictLock);
    
    ALLogVerbose(@"\nrequest: %@ will redirect to: %@", srcReq, newURL);
    [request redirectToURL:newURL];
    [srcReq setValue:newURL forKey:al_keypath(srcReq.currentURL)];
}

@end
