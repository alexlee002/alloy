//
//  Base64.m
//  Pods
//
//  Created by Alex Lee on 3/14/16.
//
//

#import "ALBase64.h"


@implementation NSString (ALExtension_Base64)

- (NSString *)al_base64Encoding {
    return [[self dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
}

- (NSString *)al_base64Decoding {
    NSData *decoded = [[self dataUsingEncoding:NSUTF8StringEncoding] al_base64Decoding];
    return [[NSString alloc] initWithData:decoded encoding:NSUTF8StringEncoding];
}

- (NSData *)al_dataByBase64Decoding {
    return [[NSData alloc] initWithBase64EncodedString:self options:NSDataBase64DecodingIgnoreUnknownCharacters];
}

- (NSData *)al_dataByBase64Eecoding {
    return [[self dataUsingEncoding:NSUTF8StringEncoding] base64EncodedDataWithOptions:0];
}

@end

@implementation NSData (ALExtension_Base64)

//NSData's base64 encoding using the Apple's native API: "-base64EncodedDataWithOptions:"


- (NSData *)al_base64Decoding {
    return [[NSData alloc] initWithBase64EncodedData:self options:NSDataBase64DecodingIgnoreUnknownCharacters];
}

@end


