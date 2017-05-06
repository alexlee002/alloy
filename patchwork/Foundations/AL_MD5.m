//
//  MD5.m
//  Pods
//
//  Created by Alex Lee on 3/14/16.
//
//

#import "AL_MD5.h"
#import <CommonCrypto/CommonDigest.h>
#import "ALUtilitiesHeader.h"
#import "NSString+Helper.h"


@implementation NSData (ALExtension_MD5)

- (NSString*)al_MD5Hash {
    const char* cStr = [self bytes];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)[self length], digest);
    return al_bytesToHexStr((const char *)digest, CC_MD5_DIGEST_LENGTH);
}

@end

@implementation NSString (ALExtension_MD5)

- (NSString*)al_MD5Hash {
    const char* cStr = [self UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];

    CC_MD5(cStr, (CC_LONG) strlen(cStr), digest);

    return al_bytesToHexStr((const char *)digest, CC_MD5_DIGEST_LENGTH);
}

@end

static uint32_t MD5bufSize = 1024 * 1024;
AL_FORCE_INLINE NSString *_Nullable al_fileMD5Hash(NSString *filepath) {
    NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath:filepath];
    if (fh == nil) {
        return nil;
    }
    
    CC_MD5_CTX md5ctx;
    CC_MD5_Init(&md5ctx);
    
    NSData *data = nil;
    while ((data = [fh readDataOfLength:MD5bufSize]).length > 0) {
        CC_MD5_Update(&md5ctx, data.bytes, (uint32_t)data.length);
    }
    [fh closeFile];
    
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &md5ctx);
    return al_bytesToHexStr((const char *)digest, CC_MD5_DIGEST_LENGTH);
}

AL_FORCE_INLINE NSString *_Nullable al_partialFileMD5Hash(NSString *filepath, NSRange range) {
    NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath:filepath];
    if (fh == nil) {
        return nil;
    }
    
    CC_MD5_CTX md5ctx;
    CC_MD5_Init(&md5ctx);
    
    uint32_t remainingBytes = (uint32_t)range.length;
    [fh seekToFileOffset:range.location];
    
    while (remainingBytes > 0) {
        uint32_t readBytes = MIN(remainingBytes, MD5bufSize);
        NSData *data = [fh readDataOfLength:readBytes];
        if (data.length == 0) {
            break;
        }
        remainingBytes -= readBytes;
        
        CC_MD5_Update(&md5ctx, data.bytes, (uint32_t)data.length);
    }
    [fh closeFile];
    
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &md5ctx);
    return al_bytesToHexStr((const char *)digest, CC_MD5_DIGEST_LENGTH);
}
