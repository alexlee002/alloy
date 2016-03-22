//
//  DES.m
//  patchwork
//
//  Created by Alex Lee on 3/22/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "DES.h"
#import <CommonCrypto/CommonCryptor.h>
#import "UtilitiesHeader.h"


static FORCE_INLINE NSData *DES_Crypt(CCOperation op, NSData *input, NSData *key) {
#if DEBUG
    assert(key.length <= kCCKeySizeAES256);
#endif
    char keyPtr[kCCKeySizeAES256 + 1];
    bzero(keyPtr, sizeof(keyPtr));
    memcpy(keyPtr, [key bytes], MIN(key.length, kCCKeySizeAES256));
    
    NSUInteger dataLength = [input length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer      = malloc(bufferSize);
    
    NSData *outputData = nil;
    size_t outputBytesLength = 0;
    CCCryptorStatus result =
        CCCrypt(op, kCCAlgorithmDES, kCCOptionPKCS7Padding | kCCOptionECBMode, keyPtr, kCCBlockSizeDES, NULL,
                [input bytes], dataLength, buffer, bufferSize, &outputBytesLength);
    if (result == kCCSuccess) {
        outputData = [NSData dataWithBytesNoCopy:buffer length:outputBytesLength];
    } else {
        ALLogWarn(@"DES Error status: %@", @(result));
    }
    free(buffer);
    return outputData;
}


@implementation NSData (ALExtension_DES)

- (NSData *)dataByDESEncryptingWithKey:(NSData *)key {
    return DES_Crypt(kCCEncrypt, self, key);
}

- (NSData *)dataByDESDecryptingWithKey:(NSData *)key {
    return DES_Crypt(kCCDecrypt, self, key);
}

@end