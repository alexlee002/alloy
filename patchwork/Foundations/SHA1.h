//
//  SHA1.h
//  Pods
//
//  Created by Alex Lee on 3/14/16.
//
//

#import <Foundation/Foundation.h>

@interface NSString (ALExtension_SHA1)

- (NSString *)sha1Encrypting;

- (NSData *)dataByHmacSHA1EncryptingWithKey:(NSData *)key;

@end

@interface NSData (ALExtension_SHA1)

- (NSString *)sha1Encrypting;

- (NSData *)dataByHmacSHA1EncryptingWithKey:(NSData *)key;

@end

