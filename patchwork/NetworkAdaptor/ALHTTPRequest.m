//
//  ALHTTPRequest.m
//  patchwork
//
//  Created by Alex Lee on 3/3/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALHTTPRequest.h"
#import "BlocksKit.h"

#define ConfirmInited(dict) do { (dict) = [NSMutableDictionary dictionary]; } while(NO)

@implementation ALHTTPRequest {
    NSMutableDictionary<NSString *, id>         *_params;
    NSMutableDictionary<NSString *, id>         *_uploadParams;
    NSMutableDictionary<NSString *, id>         *_headers;
}

@synthesize identifier                      = _identifier;
@synthesize currentURL                      = _currentURL;
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
        self.maximumnConnectionTimeout = 30.f;
    }
    ALLogVerbose(@"--- INIT: <%@:%@> ---", self.class, @(self.hash));
    return self;
}

- (void)dealloc {
    ALLogVerbose(@"~~~ DEALLOC: <%@:%@> ~~~", self.class, @(self.hash));
}

- (NSString *)description {
    NSMutableArray *components = [NSMutableArray array];
    [components addObject:[NSString stringWithFormat:@"%@ (id:%@); %@", self.class, @(self.identifier),
                                                     [self methodName]]];
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

#pragma - ALRequestProtocol

@dynamic userAgent;

- (nullable NSString *)temporaryDownloadFilePath {
    if (_temporaryDownloadFilePath == nil && _downlFilePath != nil) {
        _temporaryDownloadFilePath = [_downlFilePath stringByAppendingPathExtension:@"tmp"];
    }
    return _temporaryDownloadFilePath;
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

@end
