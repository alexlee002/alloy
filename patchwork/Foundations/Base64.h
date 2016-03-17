//
//  Base64.h
//  Pods
//
//  Created by Alex Lee on 3/14/16.
//
//

#import <Foundation/Foundation.h>

@interface NSString (ALExtension_Base64)

- (NSString *)base64Encoding;
- (NSString *)base64Decoding;

- (NSData *)dataByBase64Decoding;
- (NSData *)dataByBase64Eecoding;

@end

@interface NSData (ALExtension_Base64)

//NSData's base64 encoding using the Apple's native API: "-base64EncodedDataWithOptions:"


- (NSData *)base64Decoding;

@end
