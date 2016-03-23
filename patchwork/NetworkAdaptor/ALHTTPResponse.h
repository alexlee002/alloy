//
//  ALHTTPResponse.h
//  patchwork
//
//  Created by Alex Lee on 3/7/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ALNetwork_config.h"

NS_ASSUME_NONNULL_BEGIN

@interface ALHTTPResponse : NSObject

+ (instancetype)responseWithNSURLResponse:(NSURLResponse *)response responseData:(nullable NSData *)responseData;


@property(readonly)                 NSInteger                        statusCode;
@property(readonly, nullable, copy) NSDictionary<NSString *, id>    *headerFields;
@property(readonly, nullable)       NSData                          *responseData;
@property(readonly, nullable)       NSString                        *responseString;

@property(nullable, readonly, copy) NSString                        *MIMEType;
@property(readonly)                 long long                        expectedContentLength;
@property(nullable, readonly, copy) NSString                        *textEncodingName;
@property(nullable, readonly, copy) NSString                        *suggestedFilename;

@end

NS_ASSUME_NONNULL_END
