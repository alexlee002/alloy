//
//  NSObject+JSONTransform.m
//  patchwork
//
//  Created by Alex Lee on 3/24/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "NSObject+JSONTransform.h"
#import "UtilitiesHeader.h"

@implementation NSObject (JSONTransform)

// object => JSON
- (nullable NSString *)JSONString {
    return [[NSString alloc]initWithData:[self JSONData] encoding:NSUTF8StringEncoding];
}

- (nullable NSData *)JSONData {
    id obj = castToTypeOrNil(self, NSSet).allObjects ?: castToTypeOrNil(self, NSOrderedSet).array;
    if (obj == nil || ![NSJSONSerialization isValidJSONObject:obj]) {
        return nil;
    }
    return [NSJSONSerialization dataWithJSONObject:obj options:0 error:nil];
}


// JSON => object
- (nullable id)objectFromJSONString:(NSString *)string {
    return [string JSONObject];
}

- (nullable id)objectFromJSONData:(NSData *)data {
    return [data JSONObject];
}

@end


@implementation NSData (JSONTransform)

- (nullable id)JSONObject {
    return [NSJSONSerialization JSONObjectWithData:self options:0 error:nil];
}

@end

@implementation NSString (JSONTransform)

- (nullable id)JSONObject {
    return [[self dataUsingEncoding:NSUTF8StringEncoding] JSONObject];
}

@end
