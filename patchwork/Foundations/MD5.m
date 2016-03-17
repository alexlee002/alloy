//
//  MD5.m
//  Pods
//
//  Created by Alex Lee on 3/14/16.
//
//

#import "MD5.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSData (ALExtension_MD5)

- (NSString*)MD5 {
    const char* cStr = [self bytes];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)[self length], digest);
    return [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x", digest[0],
                                      digest[1], digest[2], digest[3], digest[4], digest[5], digest[6], digest[7],
                                      digest[8], digest[9], digest[10], digest[11], digest[12], digest[13], digest[14],
                                      digest[15]];
}

@end

@implementation NSString (ALExtension_MD5)

- (NSString*)MD5 {
    const char* cStr = [self UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];

    CC_MD5(cStr, (CC_LONG) strlen(cStr), digest);

    return [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x", digest[0],
                                      digest[1], digest[2], digest[3], digest[4], digest[5], digest[6], digest[7],
                                      digest[8], digest[9], digest[10], digest[11], digest[12], digest[13], digest[14],
                                      digest[15]];
}

@end
