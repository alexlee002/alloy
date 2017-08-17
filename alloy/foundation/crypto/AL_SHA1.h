//
//  SHA1.h
//  Pods
//
//  Created by Alex Lee on 3/14/16.
//
//

#import <Foundation/Foundation.h>

@interface NSString (ALExtension_SHA1)

- (NSString *)al_sha1EncryptingUsingEncoding:(NSStringEncoding)encoding;

- (NSData *)al_dataByHmacSHA1EncryptingUsingEncoding:(NSStringEncoding)encoding key:(NSData *)key;

@end

@interface NSData (ALExtension_SHA1)

- (NSString *)al_sha1Encrypting;

- (NSData *)al_dataByHmacSHA1EncryptingWithKey:(NSData *)key;

@end

