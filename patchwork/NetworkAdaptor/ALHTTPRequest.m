//
//  ALHTTPRequest.m
//  patchwork
//
//  Created by Alex Lee on 3/3/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALHTTPRequest.h"
#import "BlocksKit.h"

#define ConfirmInited(dict) do { if((dict) == nil) { (dict) = [NSMutableDictionary dictionary];} } while(NO)

@implementation ALHTTPRequest {
    NSMutableDictionary<NSString *, id>         *_params;
    NSMutableDictionary<NSString *, id>         *_uploadParams;
    NSMutableDictionary<NSString *, id>         *_headers;
}

@synthesize identifier                      = _identifier;
@synthesize currentURL                      = _currentURL;
@synthesize state                           = _state;
@synthesize response                        = _response;
@synthesize countOfBytesReceived            = _countOfBytesReceived;
@synthesize countOfBytesSent                = _countOfBytesSent;
@synthesize countOfBytesExpectedToSend      = _countOfBytesExpectedToSend;
@synthesize countOfBytesExpectedToReceive   = _countOfBytesExpectedToReceive;


+ (instancetype)requestWithURLString:(NSString *)url {
    ALHTTPRequest *request = [[self alloc] init];
    request.url = url;
    return request;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _identifier = [self uniqueRequestId];
        _maximumnConnectionTimeout = 30.f;
    }
    ALLogVerbose(@"--- INIT: <%@:%@> ---", self.class, @(self.hash));
    return self;
}

- (void)dealloc {
    ALLogVerbose(@"~~~ DEALLOC: <%@:%@> ~~~", self.class, @(self.hash));
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ (id:%@); %@; %@; %@", self.class, @(self.identifier), [self methodName],
                                      [self requestTypeString], [self stateString]];
}

- (NSString *)descriptionDetailed:(BOOL)detailed {
    NSString *desc = self.description;
    if (!detailed) {
        return desc;
    }
    
    NSMutableArray *components = [NSMutableArray arrayWithObject:desc];
    [components addObject:[@"url: " stringByAppendingString:self.url]];
    
    if (self.params.count > 0) {
        [components addObject:[NSString stringWithFormat:@"params: %@", self.params]];
    }
    if (self.uploadParams.count > 0) {
        [components addObject:[NSString stringWithFormat:@"upload: %@", self.uploadParams]];
    }
    if (self.headers.count > 0) {
        [components addObject:[NSString stringWithFormat:@"headers: %@", self.headers]];
    }
    
    return [components componentsJoinedByString:@"\n"];
}


- (NSUInteger)uniqueRequestId {
    static dispatch_semaphore_t lock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lock = dispatch_semaphore_create(1);
    });
    
    static NSUInteger kIdentifier = 0;
    NSUInteger nextId;
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    nextId = ++kIdentifier;
    dispatch_semaphore_signal(lock);
    return nextId;
}

#pragma mark -

- (ALHTTPRequestBlockKV)SET_PARAM {
    return ^__kindof ALHTTPRequest *_Nonnull(NSString *_Nonnull key, id _Nullable value) {
        [self setParam:value forKey:key];
        return self;
    };
}

- (ALHTTPRequestBlockDict)SET_PARAMS {
    return ^__kindof ALHTTPRequest *_Nonnull(NSDictionary<NSString *, id> *_Nullable dict) {
        [self setParams:dict];
        return self;
    };
}

- (ALHTTPRequestBlockKV)SET_UPLOAD_PARAM {
    return ^__kindof ALHTTPRequest *_Nonnull(NSString *_Nonnull key, id _Nullable value) {
        [self setUploadParam:value forKey:key];
        return self;
    };
}

- (ALHTTPRequestBlockKV)SET_HEADER {
    return ^__kindof ALHTTPRequest *_Nonnull(NSString *_Nonnull key, id _Nullable value) {
        [self setHeader:value forKey:key];
        return self;
    };
}

- (ALHTTPRequestBlockBKV)SET_PARAM_IF {
    return ^__kindof ALHTTPRequest *_Nonnull(BOOL condition, NSString *_Nonnull key, id _Nullable value) {
        if (condition) {
            [self setParam:value forKey:key];
        }
        return self;
    };
}

- (ALHTTPRequestBlockBKV)SET_UPLOAD_PARAM_IF {
    return ^__kindof ALHTTPRequest *_Nonnull(BOOL condition, NSString *_Nonnull key, id _Nullable value) {
        if (condition) {
            [self setUploadParam:value forKey:key];
        }
        return self;
    };
}

- (ALHTTPRequestBlockBKV)SET_HEADER_IF {
    return ^__kindof ALHTTPRequest *_Nonnull(BOOL condition, NSString *_Nonnull key, id _Nullable value) {
        if (condition) {
            [self setHeader:value forKey:key];
        }
        return self;
    };
}

#pragma - ALRequestProtocol

@dynamic userAgent;
@synthesize temporaryDownloadFilePath = _temporaryDownloadFilePath;
- (nullable NSString *)temporaryDownloadFilePath {
    if (_temporaryDownloadFilePath == nil && _downloadFilePath != nil) {
        _temporaryDownloadFilePath = [_downloadFilePath stringByAppendingPathExtension:@"tmp"];
    }
    return _temporaryDownloadFilePath;
}

- (void)setTemporaryDownloadFilePath:(NSString *)temporaryDownloadFilePath {
    _temporaryDownloadFilePath = [temporaryDownloadFilePath copy];
}

- (void)setParam:(id)param forKey:(NSString *)key {
    if (param == nil) {
        [_params removeObjectForKey:key];
    }
    
    ConfirmInited(_params);
    _params[key] = param;
}

- (void)setParams:(NSDictionary<NSString *, id> *)params {
    _params = [params mutableCopy];
}

- (NSDictionary<NSString *, id>  *)params {
    return [_params copy];
}

- (void)setUploadParam:(id)obj forKey:(NSString *)key {
    if (obj == nil) {
        [_uploadParams removeObjectForKey:key];
    }
    
    ConfirmInited(_uploadParams);
    _uploadParams[key] = obj;
}

- (NSDictionary<NSString *, id> *)uploadParams {
    return [_uploadParams copy];
}

- (void)setHeader:(id)header forKey:(NSString *)key {
    if (header == nil) {
        [_headers removeObjectForKey:key];
    }
    
    ConfirmInited(_headers);
    _headers[key] = header;
}

- (NSDictionary<NSString *, id> *)headers {
    return [_headers copy];
}

- (void)setUserAgent:(NSString *)ua {
    [self setHeader:ua forKey:@"User-Agent"];
}

- (nullable NSString *)userAgent {
    return _headers[@"User-Agent"];
}

- (NSString *)methodName {
    switch (self.method) {
        case ALHTTPMethodGet:    return @"GET";
        case ALHTTPMethodPost:   return @"POST";
        case ALHTTPMethodHead:   return @"HEAD";
        case ALHTTPMethodPut:    return @"PUT";
        case ALHTTPMethodDelete: return @"DELETE";
        default:                 return @"GET";
    }
}

- (NSString *)stateString {
    switch (self.state) {
        case ALHTTPRequestStateRunning:         return @"Running";
        case ALHTTPRequestStateCancelled:       return @"Cancelled";
        case ALHTTPRequestStateCompleted:       return @"Completed";
        case ALHTTPRequestStateSuspended:       return @"Suspended";
        default:                                return @"Unknown";
    }
}

- (NSString *)requestTypeString {
    switch (self.type) {
        case ALRequestTypeDownload: return @"Download request";
        case ALRequestTypeUpload:   return @"Upload request";
        case ALRequestTypeNormal:   return @"Normal request";
        default: return @"Normal request";
    }
}

@end
