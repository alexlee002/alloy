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
#import "URLHelper.h"
#import "BlocksKitExtension.h"
#import <objc/runtime.h>
#import "ObjcAssociatedObjectHelpers.h"
#import "NSArray+ArrayExtensions.h"
#import "UtilitiesHeader.h"
#import "ALLogger.h"


@interface NSURLSessionDataTaskALHTTPResponse : ALHTTPResponse {
    @package
    NSMutableData *_receivingData;
    long long      _totalRead;
}
- (void)appendResponseData:(NSData *)data;
@end

@implementation NSURLSessionDataTaskALHTTPResponse {
    NSLock *_lock;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _receivingData = [NSMutableData data];
        _lock = [[NSLock alloc] init];
    }
    return self;
}

- (void)appendResponseData:(NSData *)data {
    [_lock lock];
    _totalRead += data.length;
    [data enumerateByteRangesUsingBlock:^(const void * _Nonnull bytes, NSRange byteRange, BOOL * _Nonnull stop) {
        [_receivingData appendBytes:bytes length:byteRange.length];
    }];
    [_lock unlock];
}

- (nullable NSData *)responseData {
    return [super responseData] ?: [_receivingData copy];
}

@end




@interface NSURLSessionAdaptor() <NSURLSessionDelegate>
@end

static const void * const kSrcRequestAssociatedKey          = &kSrcRequestAssociatedKey;
static const void * const kTaskStateKVOTokenAssociatedKey   = &kTaskStateKVOTokenAssociatedKey;

@implementation NSURLSessionAdaptor {
    NSURLSession     *_session; // IMPORTANT: session retains its delegate. so there is cycle-retain here.
    
    //key: ALHTTPRequest.identifier; NSArray: @[ALHTTPRequest, NSURLSessionTask]
    NSMutableDictionary<NSNumber *, NSArray *> *_requestDict;
}

@synthesize delegate;

+ (instancetype)adaptorWithSessionConfiguration:(NSURLSessionConfiguration *)config {
    NSURLSessionAdaptor *adaptor = [[self alloc] init];
    NSOperationQueue *queue      = [[NSOperationQueue alloc] init];
    adaptor->_session            = [NSURLSession sessionWithConfiguration:config delegate:adaptor delegateQueue:queue];
    adaptor->_requestDict        = [NSMutableDictionary dictionary];
    return adaptor;
}

- (void)dealloc {
    ALLogVerbose(@"~~~ DEALLOC: %@ ~~~", self);
}

- (void)bindRequest:(ALHTTPRequest *)request toTask:(NSURLSessionTask *)task {
    objc_setAssociatedObject(task, kSrcRequestAssociatedKey, request, OBJC_ASSOCIATION_RETAIN);
    weakify(request)
    NSString *token = [task bk_addObserverForKeyPath:keypath(task.state) task:^(id target) {
        strongify(request)
        NSURLSessionTask *object = castToTypeOrNil(target, NSURLSessionTask);
        switch (object.state) {
            case NSURLSessionTaskStateRunning:
                [request setValue:@(ALHTTPRequestStateRunning) forKey:keypath(request.state)];
                break;
            case NSURLSessionTaskStateCanceling:
                [request setValue:@(ALHTTPRequestStateCancelled) forKey:keypath(request.state)];
                break;
            case NSURLSessionTaskStateCompleted:
                [request setValue:@(ALHTTPRequestStateCompleted) forKey:keypath(request.state)];
                break;
            case NSURLSessionTaskStateSuspended:
                [request setValue:@(ALHTTPRequestStateSuspended) forKey:keypath(request.state)];
                break;
            default:
                [request setValue:@(ALHTTPRequestStateRunning) forKey:keypath(request.state)];
                break;
        }
    }];
    objc_setAssociatedObject(task, kTaskStateKVOTokenAssociatedKey, token, OBJC_ASSOCIATION_RETAIN);
}

- (ALHTTPRequest *)requestWithTask:(NSURLSessionTask *)task {
    return castToTypeOrNil(objc_getAssociatedObject(task, kSrcRequestAssociatedKey), ALHTTPRequest);
}

- (void)destoryRequest:(ALHTTPRequest *)request {
    NSURLSessionTask *task = [castToTypeOrNil(_requestDict[@(request.identifier)], NSArray)objectAtIndexSafely:1];
    NSString *token = castToTypeOrNil(objc_getAssociatedObject(task, kTaskStateKVOTokenAssociatedKey), NSString);
    [castToTypeOrNil(task, NSURLSessionTask) bk_removeObserversWithIdentifier:token];
    
    [_requestDict removeObjectForKey:@(request.identifier)];
    [self bindRequest:nil toTask:task];
    ALLogVerbose(@"~~~~~ %@", _requestDict[@(request.identifier)]);
}

#pragma mark -
- (BOOL)sendRequest:(__kindof ALHTTPRequest *)request {
    NSURLSessionTask *task = nil;
    NSURLRequest *urlRequest = [self urlRequestTransformFromALRequest:request];
    if (request.type == ALRequestTypeUpload) {
        // TODO: need to support multipart request.
        // if files information are set, using stream upload
        // else if datas are set, using data upload
        
        task = [_session uploadTaskWithRequest:urlRequest fromData:urlRequest.HTTPBody];
        
    } else if (request.type == ALRequestTypeDownload) {
        task = [_session downloadTaskWithRequest:urlRequest];
    } else {
        task = [_session dataTaskWithRequest:urlRequest];
    }
    
    _requestDict[@(request.identifier)] = @[request, task];
    [self bindRequest:request toTask:task];
    
    [task resume];
    [request requestDidStart];
    return YES;
}

- (NSURLRequest *)urlRequestTransformFromALRequest:(__kindof ALHTTPRequest *)request {
    NSMutableURLRequest *urlRequest = nil;
    if (request.type == ALRequestTypeNotInitialized) {
        request.type = [request autoDetectRequestType];
    }
    if (request.uploadParams.count > 0) {
        request.method = ALHTTPMethodPost;
    }
    
    if (request.type == ALRequestTypeUpload) {
        NSURL *url = [[NSURL URLWithString:stringOrEmpty(request.url)] URLBySettingQueryParamsOfDictionary:request.params];
        urlRequest = [NSMutableURLRequest requestWithURL:url];
        [self buildUploadRequest:urlRequest fromALRequest:request];
    } else if (request.method == ALHTTPMethodPost) {
        urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:request.url]];
        [request.params bk_each:^(NSString *key, id value) {
            [urlRequest setValue:stringValue(value) forHTTPHeaderField:key];
        }];
    } else {
        NSURL *url = [[NSURL URLWithString:stringOrEmpty(request.url)] URLBySettingQueryParamsOfDictionary:request.params];
        urlRequest = [NSMutableURLRequest requestWithURL:url];
    }
    urlRequest.HTTPMethod = [request methodName];
    
    [[request headers] bk_each:^(NSString *key, id value) {
        [urlRequest setValue:stringValue(value) forHTTPHeaderField:key];
    }];
    
    return urlRequest;
}

- (void)buildUploadRequest:(NSMutableURLRequest *)request fromALRequest:(ALHTTPRequest *)alRequest {
    NSStringEncoding encoding = NSUTF8StringEncoding;
    NSString *boundaryString  = [NSString stringWithFormat:@"0xKhTmLbOuNdArY-%@", [NSString UUIDString]];
    NSString *charset =
    (NSString *) CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(encoding));
    
    NSData *boundary = [[NSString stringWithFormat:@"--%@\r\n", boundaryString] dataUsingEncoding:encoding];
    NSData *newLine  = [@"\r\n" dataUsingEncoding:encoding];
    
    NSMutableData *postData = [NSMutableData dataWithData:boundary];
    
    NSDictionary *dict = [alRequest.uploadParams bk_select:^BOOL(id key, id obj) {
        return [obj isKindOfClass:NSData.class];
    }];
    
    __block NSInteger idx = 0;
    [dict bk_each:^(id key, id obj) {
        if (idx > 0) {
            [postData appendData:newLine];
            [postData appendData:boundary];
        }
        idx ++;
        
        [postData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", key, key] dataUsingEncoding:encoding]];
        [postData appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", @"application/octet-stream"] dataUsingEncoding:encoding]];
        [postData appendData:obj];
    }];
    
    [postData appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundaryString]dataUsingEncoding:encoding]];
    
    request.HTTPBody = postData;
    
    [request setValue:[NSString
                       stringWithFormat:@"multipart/form-data; charset=%@; boundary=%@", charset, boundaryString]
   forHTTPHeaderField:@"Content-Type"];
    
    [request setValue:[NSString stringWithFormat:@"%llu", (unsigned long long)postData.length] forHTTPHeaderField:@"Content-Length"];
    
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
    if (completion == nil) {
        return;
    }
    [_session getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> *_Nonnull dataTasks,
                                              NSArray<NSURLSessionUploadTask *> *_Nonnull uploadTasks,
                                              NSArray<NSURLSessionDownloadTask *> *_Nonnull downloadTasks){
        completion([[[@[dataTasks, uploadTasks, downloadTasks] al_flatten] bk_map:^ALHTTPRequest *(NSURLSessionTask *task) {
            return [self requestWithTask:task];
        }] bk_reject:^BOOL(id obj) {
            return obj == NSNull.null;
        }]);
    }];
}

- (void)suspend {
    [_session getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> *_Nonnull dataTasks,
                                              NSArray<NSURLSessionUploadTask *> *_Nonnull uploadTasks,
                                              NSArray<NSURLSessionDownloadTask *> *_Nonnull downloadTasks){
        [[@[dataTasks, uploadTasks, downloadTasks] al_flatten] bk_each:^(NSURLSessionTask *task) {
            [task suspend];
        }];
    }];
}

- (void)resume {
    [_session getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> *_Nonnull dataTasks,
                                              NSArray<NSURLSessionUploadTask *> *_Nonnull uploadTasks,
                                              NSArray<NSURLSessionDownloadTask *> *_Nonnull downloadTasks){
        [[@[dataTasks, uploadTasks, downloadTasks] al_flatten] bk_each:^(NSURLSessionTask *task) {
            [task resume];
        }];
    }];
}

// cancel specified request
- (void)cancelRequestWithIdentifyer:(NSUInteger)identifier {
    [self cancelRequestWithIdentifyer:identifier contextHandler:nil];
}

- (void)cancelRequestWithIdentifyer:(NSUInteger)identifier
                     contextHandler:(void (^_Nullable)(id _Nullable context))handler {
    NSURLSessionTask *task = [castToTypeOrNil(_requestDict[@(identifier)], NSArray)objectAtIndexSafely:1];
    if ([task isKindOfClass:[NSURLSessionDownloadTask class]]) {
        [((NSURLSessionDownloadTask *)task) cancelByProducingResumeData:handler];
    } else {
        [castToTypeOrNil(task, NSURLSessionTask) cancel];
    }
}

// cancel all request, but the queue is still alive, and able to accept new requests.
- (void)cancellAllRequest {
    [_session getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> *_Nonnull dataTasks,
                                              NSArray<NSURLSessionUploadTask *> *_Nonnull uploadTasks,
                                              NSArray<NSURLSessionDownloadTask *> *_Nonnull downloadTasks){
        [[@[dataTasks, uploadTasks, downloadTasks] al_flatten] bk_each:^(NSURLSessionTask *task) {
            [castToTypeOrNil(task, NSURLSessionTask) cancel];
        }];
    }];
}

// waiting all requests finished and then release the queue, and can not accept new request again.
- (void)finishRequestsAndInvalidate {
    [_session finishTasksAndInvalidate];
}

// send 'cancel' message to all request and release the queue.
- (void)invalidateAndCancel {
    [_session invalidateAndCancel];
}

#pragma mark - NSURLSession delegates

- (void)URLSession:(NSURLSession *)session
                 downloadTask:(NSURLSessionDownloadTask *)downloadTask
    didFinishDownloadingToURL:(NSURL *)location {
    
    ALHTTPRequest *request = [self requestWithTask:downloadTask];
    if (request.downloadFilePath != nil) {
        NSError *error = nil;
        if (![[NSFileManager defaultManager] moveItemAtURL:location
                                                     toURL:[NSURL fileURLWithPath:request.downloadFilePath]
                                                     error:&error]) {
            ALLogError(@"ERROR: %@", error);
            request.temporaryDownloadFilePath = location.path;
        }
    } else {
        request.temporaryDownloadFilePath = location.path;
    }

    ALHTTPResponse *response =
        request.response ?: [ALHTTPResponse responseWithNSURLResponse:downloadTask.response responseData:nil];
    [request requestDidSucceedWithResponse:response];
    
    TrackMemoryLeak(request);
    TrackMemoryLeak(downloadTask);
    CheckMemoryLeak(request);
    CheckMemoryLeak(downloadTask);
    [self destoryRequest:request];
}

//@optional
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error {
    ALLogInfo(@"session: %@ become invalid. Error: %@", _session, error);
    TrackMemoryLeak(_session);
    CheckMemoryLeak(_session);
    _session = nil;
}

- (void)URLSession:(NSURLSession *)session
    didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
      completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition,
                                  NSURLCredential *__nullable credential))completionHandler {
    ALLogVerbose(@"%@", session);
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    ALLogVerbose(@"%@", session);
}

- (void)URLSession:(NSURLSession *)session
                          task:(NSURLSessionTask *)task
    willPerformHTTPRedirection:(NSHTTPURLResponse *)response
                    newRequest:(NSURLRequest *)request
             completionHandler:(void (^)(NSURLRequest *__nullable))completionHandler {
    
    ALLogVerbose(@"%@", task);
    ALHTTPRequest *srcReq = [self requestWithTask:task];
    [srcReq setValue:request.URL forKey:keypath(srcReq.currentURL)];
    completionHandler(request);
}

- (void)URLSession:(NSURLSession *)session
                   task:(NSURLSessionTask *)task
    didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
      completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition,
                                  NSURLCredential *__nullable credential))completionHandler {
    ALLogVerbose(@"%@", task);
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
 needNewBodyStream:(void (^)(NSInputStream *__nullable bodyStream))completionHandler {
    ALLogVerbose(@"%@", task);
    //TODO: not implemented yet
}

- (void)URLSession:(NSURLSession *)session
                        task:(NSURLSessionTask *)task
             didSendBodyData:(int64_t)bytesSent
              totalBytesSent:(int64_t)totalBytesSent
    totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    
    ALHTTPRequest *request = [self requestWithTask:task];
    [request requestDidSendBytes:bytesSent
                  totalBytesSent:totalBytesSent
        totalBytesExpectedToSend:totalBytesExpectedToSend];
}

- (void)URLSession:(NSURLSession *)session
                    task:(NSURLSessionTask *)task
    didCompleteWithError:(nullable NSError *)error {

    ALHTTPRequest *request = [self requestWithTask:task];
    ALHTTPResponse *response =
        request.response ?: [ALHTTPResponse responseWithNSURLResponse:task.response responseData:nil];
    [request requestDidSucceedWithResponse:response];

    TrackMemoryLeak(request);
    TrackMemoryLeak(task);
    CheckMemoryLeak(request);
    CheckMemoryLeak(task);
    [self destoryRequest:request];
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    
    ALLogVerbose(@"%@", dataTask);
    ALHTTPRequest *request = [self requestWithTask:dataTask];
    ALHTTPResponse *alResponse = [NSURLSessionDataTaskALHTTPResponse responseWithNSURLResponse:response responseData:nil];
    [request setValue:alResponse forKey:keypath(request.response)];
    
    completionHandler(NSURLSessionResponseAllow);
    NSHTTPURLResponse *httpResponse = castToTypeOrNil(response, NSHTTPURLResponse);
    [request requestDidReceiveResponse:httpResponse.statusCode headers:httpResponse.allHeaderFields];
}

- (void)URLSession:(NSURLSession *)session
                 dataTask:(NSURLSessionDataTask *)dataTask
    didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask {
    
    ALLogVerbose(@"%@ => %@", dataTask, downloadTask);
}

- (void)URLSession:(NSURLSession *)session
               dataTask:(NSURLSessionDataTask *)dataTask
    didBecomeStreamTask:(NSURLSessionStreamTask *)streamTask {
    ALLogVerbose(@"%@ => %@", dataTask, streamTask);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    ALLogVerbose(@"%@", dataTask);
    ALHTTPRequest *request     = [self requestWithTask:dataTask];
    NSURLSessionDataTaskALHTTPResponse *alResponse = castToTypeOrNil(request.response, NSURLSessionDataTaskALHTTPResponse);
    [alResponse appendResponseData:data];

    [request requestDidReceiveBytes:data.length
                 totalBytesReceived:alResponse == nil ? 0 : alResponse->_totalRead
        totalBytesExpectedToReceive:alResponse == nil ? 0 : alResponse.expectedContentLength];
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
 willCacheResponse:(NSCachedURLResponse *)proposedResponse
 completionHandler:(void (^)(NSCachedURLResponse *__nullable cachedResponse))completionHandler {
    
    ALLogVerbose(@"%@", dataTask);
    completionHandler(proposedResponse);
}

- (void)URLSession:(NSURLSession *)session
                 downloadTask:(NSURLSessionDownloadTask *)downloadTask
                 didWriteData:(int64_t)bytesWritten
            totalBytesWritten:(int64_t)totalBytesWritten
    totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    
    ALHTTPRequest *request = [self requestWithTask:downloadTask];
    [request requestDidReceiveBytes:bytesWritten
                 totalBytesReceived:totalBytesWritten
        totalBytesExpectedToReceive:totalBytesExpectedToWrite];
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes {
    
    ALLogVerbose(@"%@", downloadTask);
    ALHTTPRequest *request = [self requestWithTask:downloadTask];
    [request requestDidReceiveBytes:0
                 totalBytesReceived:fileOffset
        totalBytesExpectedToReceive:expectedTotalBytes];
}

@end
