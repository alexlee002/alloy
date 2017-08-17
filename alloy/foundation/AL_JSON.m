//
//  NSObject+JSONTransform.m
//  patchwork
//
//  Created by Alex Lee on 3/24/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "AL_JSON.h"
#import "ALUtilitiesHeader.h"

@implementation NSObject (ALExtension_JSON)

// object => JSON
- (nullable NSString *)al_JSONString {
    return [[NSString alloc]initWithData:[self al_JSONData] encoding:NSUTF8StringEncoding];
}

- (nullable NSData *)al_JSONData {
    id obj = ALCastToTypeOrNil(self, NSSet).allObjects ?: (ALCastToTypeOrNil(self, NSOrderedSet).array ?: self);
    if (obj == nil || ![NSJSONSerialization isValidJSONObject:obj]) {
        return nil;
    }
    return [NSJSONSerialization dataWithJSONObject:obj options:0 error:nil];
}


// JSON => object
- (nullable id)al_objectFromJSONString:(NSString *)string {
    return [string al_JSONObject];
}

- (nullable id)al_objectFromJSONData:(NSData *)data {
    return [data al_JSONObject];
}

@end


@implementation NSData (ALExtension_JSON)

- (nullable id)al_JSONObject {
    return [NSJSONSerialization JSONObjectWithData:self options:0 error:nil];
}

@end

@implementation NSString (ALExtension_JSON)

- (nullable id)al_JSONObject {
    return [[self dataUsingEncoding:NSUTF8StringEncoding] al_JSONObject];
}

@end
