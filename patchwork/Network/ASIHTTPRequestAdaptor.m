//
//  ASIHTTPRequestAdapter.m
//  patchwork
//
//  Created by Alex Lee on 3/3/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//


#import "ALNetwork_config.h"

#if AL_ENABLE_ASIHTTPREQUEST

#if DEBUG
    #define DEBUG_REQUEST_STATUS    1
    #define DEBUG_FORM_DATA_REQUEST 1
    #define DEBUG_THROTTLING        1
#endif


#import "ASIHTTPRequestAdaptor.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "ASIBandwidthHttpRequest.h"
#import "BlocksKit.h"
#import "StringHelper.h"
#import "UtilitiesHeader.h"
#import "ALHTTPResponse.h"

NS_ASSUME_NONNULL_BEGIN

#define requestDesc(srcReq)    [NSString stringWithFormat:@"%@ (id:%@)", (srcReq).class, @((srcReq).identifier)]
#define sourceRequestOf(request)    (request).userInfo[kALRequestKey]

static NSString * const kALRequestKey = @"__ALRequest";

@interface ASIHTTPRequestAdaptor () <ASIHTTPRequestDelegate, ASIProgressDelegate>
@end

@implementation ASIHTTPRequestAdaptor {
    NSMutableDictionary *_asiRequests;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _asiRequests = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSDictionary<NSNumber *, id> *)allRequestObjects {
    return _asiRequests;
}

#pragma mark - request tramsform
- (id)objectTransformFromALRequest:(__kindof ALHTTPRequest *)request {
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
            NSURL *url  = [NSURL URLWithString:[stringOrEmpty(request.url) stringbyAppendingQueryItems:request.params]];
            asiRequest = [ASIHTTPRequest requestWithURL:url];
        }
    }
    
    switch (request.method) {
        case ALHTTPMethodGet:
            asiRequest.requestMethod = @"GET";
            break;
        case ALHTTPMethodPost:
            asiRequest.requestMethod = @"POST";
            break;
        case ALHTTPMethodHead:
            asiRequest.requestMethod = @"HEAD";
            break;
        case ALHTTPMethodPut:
            asiRequest.requestMethod = @"PUT";
            break;
        case ALHTTPMethodDelete:
            asiRequest.requestMethod = @"DELETE";
            break;
            
        default:
            asiRequest.requestMethod = @"GET";
            break;
    }
    
    [[request headers] bk_each:^(NSString *key, id value) {
        [asiRequest addRequestHeader:key value:value];
    }];
    
    if (!isEmptyString(request.userAgent)) {
        asiRequest.userAgentString = request.userAgent;
    }
    
    asiRequest.delegate = self;
    asiRequest.useCookiePersistence = NO;
    asiRequest.timeOutSeconds = request.maximumnConnectionTimeout;
    asiRequest.userInfo = @{kALRequestKey: request};
    asiRequest.needHiddenIndicator = request.hideNetworkIndicator;
    asiRequest.needParseResponseAsynchronous = YES;
    asiRequest.tag = [self uniqueRequestId];
    [(NSObject *)request setValue:@(asiRequest.tag) forKey:@"identifier"];
    
    return asiRequest;
}

- (void)buildUploadRequest:(ASIHTTPRequest **)asiRequest with:(__kindof ALHTTPRequest *)request {
    [request.fileParams bk_each:^(NSString *key, id fileObj) {
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
    *asiRequest = [ASIBandwidthHttpRequest requestWithURL:url];
    ((ASIBandwidthHttpRequest *) (*asiRequest)).maxBandwidthPerSecond = (unsigned long) request.bytesPerSecond;
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
    NSUInteger nextId = kIdentifier;
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    nextId = ++kIdentifier;
    dispatch_semaphore_signal(lock);
    return nextId;
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
    if (srcReq.completionBlock != nil) {
        srcReq.completionBlock([ALHTTPResponse responseWithASIHttpRequest:request], nil);
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request {
    ALHTTPRequest *srcReq = sourceRequestOf(request);
    ALLogVerbose(@"\nrequest: %@\nerror: %@", requestDesc(srcReq), request.responseString);
    if (srcReq.completionBlock != nil) {
        srcReq.completionBlock([ALHTTPResponse responseWithASIHttpRequest:request], request.error);
    }
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


@end

NS_ASSUME_NONNULL_END

#endif
