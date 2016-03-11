//
//  ALHTTPResponse.m
//  patchwork
//
//  Created by Alex Lee on 3/7/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALHTTPResponse.h"
#import "NSString+Helper.h"

#if AL_ENABLE_ASIHTTPREQUEST
#import "ASIHTTPRequest.h"
#endif


@implementation ALHTTPResponse {
//#if AL_ENABLE_ASIHTTPREQUEST
//    ASIHTTPRequest *_asiRequest;
//    NSString       *_MIMEType;
//    NSString       *_textEncodingName;
//#endif
    NSHTTPURLResponse  *_NSURLResponse;
    NSData             *_responseData;
}

#if AL_ENABLE_ASIHTTPREQUEST
+ (instancetype)responseWithASIHttpRequest:(ASIHTTPRequest *)request {
    //    ALHTTPResponse *response = [[ALHTTPResponse alloc] init];
    //    response->_asiRequest = request;
    //    return response;
    NSHTTPURLResponse *nsResponse = [[NSHTTPURLResponse alloc]
         initWithURL:request.url
          statusCode:request.responseStatusCode
         HTTPVersion:((__bridge NSString *) (request.useHTTPVersionOne ? kCFHTTPVersion1_0 : kCFHTTPVersion1_1))
        headerFields:request.responseHeaders];
    return [self responseWithNSURLResponse:nsResponse responseData:request.responseData];
}
#endif

+ (instancetype)responseWithNSURLResponse:(NSHTTPURLResponse *)nsResponse responseData:(nullable NSData *)responseData {
    ALHTTPResponse *response = [[ALHTTPResponse alloc] init];
    response->_NSURLResponse = nsResponse;
    response->_responseData  = responseData;
    return response;
}

- (NSInteger)statusCode {
//#if AL_ENABLE_ASIHTTPREQUEST
//    if (_asiRequest) {
//        return _asiRequest.responseStatusCode;
//    }
//#endif
    return _NSURLResponse.statusCode;
}

- (nullable NSDictionary<NSString *, id> *)headerFields {
//#if AL_ENABLE_ASIHTTPREQUEST
//    if (_asiRequest) {
//        return _asiRequest.responseHeaders;
//    }
//#endif
    return _NSURLResponse.allHeaderFields;
}

- (nullable NSString *)MIMEType {
//#if AL_ENABLE_ASIHTTPREQUEST
//    if (_asiRequest) {
//        [self parseContentType:[_asiRequest.responseHeaders[@"Content-Type"] stringify]];
//        return _MIMEType;
//    }
//#endif
    return _NSURLResponse.MIMEType;
}

- (nullable NSString *)textEncodingName {
//#if AL_ENABLE_ASIHTTPREQUEST
//    if (_asiRequest) {
//        [self parseContentType:[_asiRequest.responseHeaders[@"Content-Type"] stringify]];
//        return _textEncodingName;
//    }
//#endif
    return _NSURLResponse.textEncodingName;
}

- (long long)expectedContentLength {
//#if AL_ENABLE_ASIHTTPREQUEST
//    if (_asiRequest) {
//        return _asiRequest.contentLength;
//    }
//#endif
    return _NSURLResponse.expectedContentLength;
}

- (nullable NSString *)suggestedFilename {
//#if AL_ENABLE_ASIHTTPREQUEST
//    if (_asiRequest) {
//        return _asiRequest.responseString;
//    }
//#endif
    return _NSURLResponse.suggestedFilename;
}


- (nullable NSData *)responseData {
//#if AL_ENABLE_ASIHTTPREQUEST
//    if (_asiRequest) {
//        return _asiRequest.responseData;
//    }
//#endif
    return _responseData;
}

- (nullable NSString *)responseString {
//#if AL_ENABLE_ASIHTTPREQUEST
//    if (_asiRequest) {
//        return _asiRequest.responseString;
//    }
//#endif
    return [[NSString alloc] initWithData:self.responseData encoding:NSStringEncodingWithName(self.textEncodingName)];
}


#pragma mark - utils
//- (void)parseContentType:(NSString *)contentType {
//    if (isEmptyString(_MIMEType) && isEmptyString(_textEncodingName) && !isEmptyString(contentType)) {
//        NSString *mimeType = nil;
//        NSString *encoding = nil;
//        
//        NSScanner *charsetScanner = [NSScanner scannerWithString:contentType];
//        if (![charsetScanner scanUpToString:@";" intoString:&mimeType] ||
//            [charsetScanner scanLocation] == [contentType length]) {
//            mimeType = [contentType stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
//        } else {
//            mimeType = [mimeType stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
//            NSString *charsetSeparator = @"charset=";
//            
//            if ([charsetScanner scanUpToString:charsetSeparator intoString:NULL] &&
//                [charsetScanner scanLocation] < [contentType length]) {
//                [charsetScanner setScanLocation:[charsetScanner scanLocation] + [charsetSeparator length]];
//                [charsetScanner scanUpToString:@";" intoString:&encoding];
//            }
//        }
//        _MIMEType = mimeType;
//        _textEncodingName = encoding;
//    }
//}
@end
