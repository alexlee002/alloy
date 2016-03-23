//
//  ALHTTPResponse.m
//  patchwork
//
//  Created by Alex Lee on 3/7/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALHTTPResponse.h"
#import "NSString+Helper.h"


@implementation ALHTTPResponse {
    NSHTTPURLResponse  *_NSURLResponse;
    NSData             *_responseData;
}

+ (instancetype)responseWithNSURLResponse:(NSURLResponse *)nsResponse responseData:(nullable NSData *)responseData {
    ALHTTPResponse *response = [[self alloc] init];
    response->_NSURLResponse = castToTypeOrNil(nsResponse, NSHTTPURLResponse);
    response->_responseData  = responseData;
    return response;
}

- (NSInteger)statusCode {
    return _NSURLResponse.statusCode;
}

- (nullable NSDictionary<NSString *, id> *)headerFields {
    return _NSURLResponse.allHeaderFields;
}

- (nullable NSString *)MIMEType {
    return _NSURLResponse.MIMEType;
}

- (nullable NSString *)textEncodingName {
    return _NSURLResponse.textEncodingName;
}

- (long long)expectedContentLength {
    return _NSURLResponse.expectedContentLength;
}

- (nullable NSString *)suggestedFilename {
    return _NSURLResponse.suggestedFilename;
}


- (nullable NSData *)responseData {
    return _responseData;
}

- (nullable NSString *)responseString {
    if (self.responseData && !isEmptyString(self.textEncodingName)) {
        return [[NSString alloc] initWithData:self.responseData encoding:NSStringEncodingWithName(self.textEncodingName)];
    }
    return nil;
}

@end
