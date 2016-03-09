//
//  ALHTTPResponse.h
//  patchwork
//
//  Created by Alex Lee on 3/7/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ASIHTTPRequest;
@interface ALHTTPResponse : NSObject

+ (instancetype)responseWithASIHttpRequest:(ASIHTTPRequest *)request;
+ (instancetype)responseWithNSHTTPURLResponse:(NSHTTPURLResponse *)response;


- (NSInteger)statusCode;
- (NSDictionary<NSString *, id> *)headerFields;
- (NSData *)responseData;


@end
