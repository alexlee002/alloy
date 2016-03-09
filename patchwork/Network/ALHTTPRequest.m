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
    NSMutableDictionary<NSString *, id>         *_fileParams;
    NSMutableDictionary<NSString *, id>         *_headers;
}

@synthesize identifier = _identifier;

- (instancetype)init {
    self = [super init];
    if (self) {
        self.maximumnConnectionTimeout = 30.f;
    }
    return self;
}

- (NSString *)description {
    NSMutableArray *components = [NSMutableArray array];
    [components addObject:[NSString stringWithFormat:@"%@ (id:%@); %@", self.class, @(self.identifier),
                                                     [self requestMethodName]]];
    [components addObject:[@"url: " stringByAppendingString:self.url]];
    
    if (self.params.count > 0) {
        [components addObject:[NSString stringWithFormat:@"params: %@", self.params]];
    }
    if (self.fileParams.count > 0) {
        [components addObject:[NSString stringWithFormat:@"upload: %@", self.fileParams]];
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

- (ALHTTPRequestBlockKV)SET_FILE_PARAM {
    return ^__kindof ALHTTPRequest *_Nonnull(NSString *_Nonnull key, id _Nullable value) {
        [self setFileParam:value forKey:key];
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
//@synthesize url                     = _url;
//@synthesize type                    = _type;
//@synthesize method                  = _method;
//@synthesize identifier              = _identifier;
//@synthesize maximumnConnectionTimeout = _maximumnConnectionTimeout;
//@synthesize hideNetworkIndicator    = _hideNetworkIndicator;
//@synthesize downlFilePath           = _downlFilePath;
//@synthesize temporaryDownloadFilePath = _temporaryDownloadFilePath;
//@synthesize startBlock              = _startBlock;
//@synthesize headersRespondsBlock    = _headersRespondsBlock;
//@synthesize progressBlock           = _progressBlock;
//@synthesize successBlock            = _successBlock;
//@synthesize failedBlock             = _failedBlock;

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

- (void)setFileParam:(id)obj forKey:(NSString *)key {
    if (obj == nil) {
        [_fileParams removeObjectForKey:key];
    }
    
    ConfirmInited(_fileParams);
    _fileParams[key] = obj;
}

- (NSDictionary<NSString *, id> *)fileParams {
    return [_fileParams copy];
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

- (NSString *)requestMethodName {
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
