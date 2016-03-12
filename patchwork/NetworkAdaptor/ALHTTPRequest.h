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

// obj = nil then reamove the value for specified key.
typedef __kindof ALHTTPRequest *_Nonnull (^ALHTTPRequestBlockKV)  (NSString *_Nonnull key, id _Nullable value);
typedef __kindof ALHTTPRequest *_Nonnull (^ALHTTPRequestBlockDict)(NSDictionary<NSString *, id> *_Nullable dict);

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


@property(PROP_ATOMIC_DEF, copy, nullable)    NSString        *downlFilePath;
// readonly if using NSURLSession
@property(PROP_ATOMIC_DEF, copy, nullable)    NSString        *temporaryDownloadFilePath;

@property(nullable, readonly, copy) NSURL               *currentURL;
@property(readonly)                 ALHTTPRequestState   state;

/* number of body bytes already received */
@property(readonly) int64_t countOfBytesReceived;
/* number of body bytes already sent */
@property(readonly) int64_t countOfBytesSent;
/* number of body bytes we expect to send, derived from the Content-Length of the HTTP request */
@property(readonly) int64_t countOfBytesExpectedToSend;
/* number of byte bytes we expect to receive, usually derived from the Content-Length header of an HTTP response. */
@property(readonly) int64_t countOfBytesExpectedToReceive;


@property(PROP_ATOMIC_DEF, copy) void (^startBlock)          (void);
@property(PROP_ATOMIC_DEF, copy) void (^headersRespondsBlock)(NSDictionary<NSString *, id> *headers);
@property(PROP_ATOMIC_DEF, copy) void (^progressBlock)       (uint64_t bytesRead, uint64_t totalBytesRead, uint64_t totalExpectedToRead);
@property(PROP_ATOMIC_DEF, copy) void (^completionBlock)     (ALHTTPResponse *response, NSError *_Nullable error);


+ (instancetype)requestWithURLString:(NSString *)url;

- (NSString *)methodName;

// obj = nil then reamove the value for specified key.
- (void)setParam:(nullable id)obj forKey:(NSString *)key;
- (void)setParams:(NSDictionary<NSString *, id> *)params;
- (NSDictionary<NSString *, id>  *)params;

// support multipart upload
- (void)setUploadParam:(nullable id)obj forKey:(NSString *)key;
- (NSDictionary<NSString *, id> *)uploadParams;

- (void)setHeader:(nullable id)header forKey:(NSString *)key;
- (NSDictionary<NSString *, id> *)headers;

@end

@interface ALHTTPRequest (BlockMethods)
@property(readonly) ALHTTPRequestBlockKV     SET_PARAM;
@property(readonly) ALHTTPRequestBlockDict   SET_PARAMS;

@property(readonly) ALHTTPRequestBlockKV     SET_UPLOAD_PARAM;
@property(readonly) ALHTTPRequestBlockKV     SET_HEADER;
@end

NS_ASSUME_NONNULL_END
