//
//  SHA1.m
//  Pods
//
//  Created by Alex Lee on 3/14/16.
//
//

#import "AL_SHA1.h"
#import <CommonCrypto/CommonHMAC.h>

@implementation NSData (ALExtension_SHA1)

- (NSString *)al_sha1Encrypting {
    NSMutableString *output = nil;
    unsigned char hashed[CC_SHA1_DIGEST_LENGTH];
    if ( CC_SHA1([self bytes], (CC_LONG)[self length], hashed) ) {
        output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
        for(NSInteger i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
            [output appendFormat:@"%02x", hashed[i]];
        }
    }
    
    return [output copy];
}

- (NSData *)al_dataByHmacSHA1EncryptingWithKey:(NSData *)key {
    void* buffer = malloc(CC_SHA1_DIGEST_LENGTH);
    CCHmac(kCCHmacAlgSHA1, [key bytes], [key length], [self bytes], [self length], buffer);
    return [NSData dataWithBytesNoCopy:buffer length:CC_SHA1_DIGEST_LENGTH freeWhenDone:YES];
}

@end


@implementation NSString (ALExtension_SHA1)

- (NSString *)al_sha1EncryptingUsingEncoding:(NSStringEncoding)encoding {
    return [[self dataUsingEncoding:encoding] al_sha1Encrypting];
}

- (NSData *)al_dataByHmacSHA1EncryptingUsingEncoding:(NSStringEncoding)encoding key:(NSData *)key {
    return [[self dataUsingEncoding:encoding] al_dataByHmacSHA1EncryptingWithKey:key];
}

@end
