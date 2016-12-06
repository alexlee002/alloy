//
//  ALHTTPRequest.h
//  patchwork
//
//  Created by Alex Lee on 3/3/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UtilitiesHeader.h"

typedef NS_ENUM(NSInteger, ALRequestType){
    ALRequestTypeNormal = 0,
    ALRequestTypeDownload,
    ALRequestTypeUpload
};

extern const NSInteger ALRequestTypeNotInitialized;

typedef NS_ENUM(NSInteger, ALHTTPMethod){
    ALHTTPMethodGet = 0,
    ALHTTPMethodPost,
    ALHTTPMethodHead,
    ALHTTPMethodPut,
    ALHTTPMethodDelete
};

typedef NS_ENUM(NSInteger, ALHTTPRequestState) {
    ALHTTPRequestStateRunning       = 0,
    ALHTTPRequestStateSuspended     = 1,
    ALHTTPRequestStateCancelled     = 2,
    ALHTTPRequestStateCompleted     = 3,
};

NS_ASSUME_NONNULL_BEGIN

@class ALHTTPRequest;
@class ALHTTPResponse;

typedef void (^ALHTTPHeaderBlock)  (NSDictionary<NSString *, id> *headers, NSInteger statusCode, NSUInteger identifier);
typedef void (^ALHTTPProgressBlock)(uint64_t bytesDone, uint64_t totalBytesDone, uint64_t totalBytesExpected,
                                    NSUInteger identifier);
typedef void (^ALHTTPCompletionBlock)    (ALHTTPResponse *response, NSError *_Nullable error, NSUInteger identifier);
// response model should be ALModel or NSArray<ALModel *>
typedef void (^ALHTTPResponseModelBlock) (id _Nullable responseModel, NSError *_Nullable error, NSUInteger identifier);

// obj = nil then reamove the value for specified key.
typedef __kindof ALHTTPRequest *_Nonnull (^ALHTTPRequestBlockKV)  (NSString *_Nonnull key, id _Nullable value);
typedef __kindof ALHTTPRequest *_Nonnull (^ALHTTPRequestBlockDict)(NSDictionary<NSString *, id> *_Nullable dict);

typedef __kindof ALHTTPRequest *_Nonnull (^ALHTTPRequestBlockBKV)(BOOL condition, NSString *_Nonnull key,
                                                                  id _Nullable value);

@interface ALHTTPRequest : NSObject

@property(readonly)                        NSUInteger       identifier;
@property(PROP_ATOMIC_DEF, copy)           NSString        *url;
@property(PROP_ATOMIC_DEF)                 ALRequestType    type;
@property(PROP_ATOMIC_DEF)                 ALHTTPMethod     method;
@property(PROP_ATOMIC_DEF)                 uint64_t         bytesPerSecond; // bandwidth throttle, eg: in 3g/2g network
@property(PROP_ATOMIC_DEF)                 NSTimeInterval   maximumnConnectionTimeout;
@property(PROP_ATOMIC_DEF, copy, nullable) NSString        *userAgent;
@property(PROP_ATOMIC_DEF)                 BOOL             hideNetworkIndicator;
@property(PROP_ATOMIC_DEF)                 float            priority;


@property(PROP_ATOMIC_DEF, copy, nullable)    NSString        *downloadFilePath;
// readonly if using NSURLSession
@property(PROP_ATOMIC_DEF, copy, nullable)    NSString        *temporaryDownloadFilePath;

@property(nullable, readonly, copy) NSURL               *currentURL;
@property(readonly)                 ALHTTPRequestState   state;
@property(nullable, readonly)       ALHTTPResponse      *response;
@property(PROP_ATOMIC_DEF, unsafe_unretained, nullable) Class  responseModelClass;

/* number of body bytes already received */
@property(readonly) int64_t countOfBytesReceived;
/* number of body bytes already sent */
@property(readonly) int64_t countOfBytesSent;
/* number of body bytes we expect to send, derived from the Content-Length of the HTTP request */
@property(readonly) int64_t countOfBytesExpectedToSend;
/* number of byte bytes we expect to receive, usually derived from the Content-Length header of an HTTP response. */
@property(readonly) int64_t countOfBytesExpectedToReceive;

@property(PROP_ATOMIC_DEF, copy, nullable) void (^startBlock)(NSUInteger identifier);

@property(PROP_ATOMIC_DEF, copy, nullable) ALHTTPHeaderBlock    responseHeaderBlock;

@property(PROP_ATOMIC_DEF, copy, nullable) ALHTTPProgressBlock  progressBlock;

/**
 *  call back when request is finished, return RAW HTTP response or error
 */
@property(PROP_ATOMIC_DEF, copy, nullable) ALHTTPCompletionBlock completionBlock;
/**
 *  @discussion return a model object that mapped from response JSON, the modelClass properity must be specified.
 *
 *  @see completionBlock
 */
@property(PROP_ATOMIC_DEF, copy, nullable) ALHTTPResponseModelBlock responseModelBlock;

+ (instancetype)requestWithURLString:(NSString *)url;

- (NSString *)methodName;
- (NSString *)descriptionDetailed:(BOOL)detailed;

// obj = nil then reamove the value for specified key.
- (void)setParam:(nullable id)obj forKey:(NSString *)key;
- (void)setParams:(NSDictionary<NSString *, id> *)params;
- (nullable NSDictionary<NSString *, id>  *)params;

// support multipart upload
- (void)setUploadParam:(nullable id)obj forKey:(NSString *)key;
- (nullable NSDictionary<NSString *, id> *)uploadParams;

- (void)setHeader:(nullable id)header forKey:(NSString *)key;
- (NSDictionary<NSString *, id> *)headers;

- (void)setPostBody:(nullable NSData *)data;
- (nullable NSData *)postBody;

- (ALRequestType)autoDetectRequestType;

@end

@interface ALHTTPRequest (BlockMethods)
@property(readonly) ALHTTPRequestBlockKV     SET_PARAM;
@property(readonly) ALHTTPRequestBlockDict   SET_PARAMS;

@property(readonly) ALHTTPRequestBlockKV     SET_UPLOAD_PARAM;
@property(readonly) ALHTTPRequestBlockKV     SET_HEADER;

@property(readonly) ALHTTPRequestBlockBKV    SET_PARAM_IF;
@property(readonly) ALHTTPRequestBlockBKV    SET_UPLOAD_PARAM_IF;
@property(readonly) ALHTTPRequestBlockBKV    SET_HEADER_IF;
@end

@class ALModel;
@interface ALHTTPRequest (ResponseEvents)
- (void)requestDidStart;
- (void)requestDidReceiveResponse:(NSInteger)statusCode headers:(nullable NSDictionary *)headers;

- (void)requestDidReceiveBytes:(int64_t)bytes
            totalBytesReceived:(int64_t)totalBytesReceived
   totalBytesExpectedToReceive:(int64_t)totalBytesExpectedToReceive;

- (void)requestDidSendBytes:(int64_t)bytes
             totalBytesSent:(int64_t)totalBytesSent
   totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend;

- (void)requestDidSucceedWithResponse:(nullable ALHTTPResponse *)response;
- (void)requestDidFailWithResponse:(nullable ALHTTPResponse *)response error:(nullable NSError *)error;

#pragma mark - methods to be override by subclasses
// return result should be ALModel or NSArray<ALModel *>
- (nullable id)modelByParsingResponseJSON:(in id)JSONObject error:(inout NSError **)error;

@end

NS_ASSUME_NONNULL_END
