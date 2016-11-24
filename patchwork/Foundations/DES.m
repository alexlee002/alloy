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
#import "ALLogger.h"


static FORCE_INLINE NSData *DES_Crypt(CCOperation op, NSData *input, NSData *key) {
    char keyPtr[kCCBlockSizeDES + 1];
    bzero(keyPtr, sizeof(keyPtr));
    memcpy(keyPtr, [key bytes], MIN(key.length, kCCBlockSizeDES));
    
    size_t bufferSize = (input.length + kCCBlockSizeDES) & ~(kCCBlockSizeDES - 1);
    uint8_t *outputBytes = malloc(bufferSize * sizeof(uint8_t));
    memset((void *)outputBytes, 0x0, bufferSize);
    size_t outputBytesLength = 0;
    
    CCCryptorStatus result = CCCrypt(op,
                                     kCCAlgorithmDES,
                                     kCCOptionPKCS7Padding | kCCOptionECBMode,
                                     keyPtr,
                                     kCCBlockSizeDES,
                                     NULL,
                                     [input bytes],
                                     input.length,
                                     outputBytes,
                                     bufferSize,
                                     &outputBytesLength);
    if (result == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:outputBytes length:outputBytesLength];
    } else {
        ALLogWarn(@"*** DES Error status: %@", @(result));
    }
    free(outputBytes);
    return nil;
}


@implementation NSData (ALExtension_DES)

- (NSData *)dataByDESEncryptingWithKey:(NSData *)key {
    return DES_Crypt(kCCEncrypt, self, key);
}

- (NSData *)dataByDESDecryptingWithKey:(NSData *)key {
    return DES_Crypt(kCCDecrypt, self, key);
}

@end
