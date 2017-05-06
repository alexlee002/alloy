//
//  Base64.h
//  Pods
//
//  Created by Alex Lee on 3/14/16.
//
//

#import <Foundation/Foundation.h>

@interface NSString (ALExtension_Base64)

- (NSString *)al_base64Encoding;
- (NSString *)al_base64Decoding;

- (NSData *)al_dataByBase64Decoding;
- (NSData *)al_dataByBase64Eecoding;

@end

@interface NSData (ALExtension_Base64)

//NSData's base64 encoding using the Apple's native API: "-base64EncodedDataWithOptions:"


- (NSData *)al_base64Decoding;

@end
