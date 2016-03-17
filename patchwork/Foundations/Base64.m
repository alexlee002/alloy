//
//  Base64.m
//  Pods
//
//  Created by Alex Lee on 3/14/16.
//
//

#import "Base64.h"


@implementation NSString (ALExtension_Base64)

- (NSString *)base64Encoding {
    return [[self dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
}

- (NSString *)base64Decoding {
    NSData *decoded = [[self dataUsingEncoding:NSUTF8StringEncoding] base64Decoding];
    return [[NSString alloc] initWithData:decoded encoding:NSUTF8StringEncoding];
}

- (NSData *)dataByBase64Decoding {
    return [[NSData alloc] initWithBase64EncodedString:self options:NSDataBase64DecodingIgnoreUnknownCharacters];
}

- (NSData *)dataByBase64Eecoding {
    return [[self dataUsingEncoding:NSUTF8StringEncoding] base64EncodedDataWithOptions:0];
}

@end

@implementation NSData (ALExtension_Base64)

//NSData's base64 encoding using the Apple's native API: "-base64EncodedDataWithOptions:"


- (NSData *)base64Decoding {
    return [[NSData alloc] initWithBase64EncodedData:self options:NSDataBase64DecodingIgnoreUnknownCharacters];
}

@end


