//
//  NSObject+JSONTransform.h
//  patchwork
//
//  Created by Alex Lee on 3/24/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (ALExtension_JSON)

- (nullable NSString *)al_JSONString;
- (nullable NSData *)al_JSONData;

- (nullable id)al_objectFromJSONString:(NSString *)string;
- (nullable id)al_objectFromJSONData:(NSData *)data;

@end

@interface NSData (ALExtension_JSON)

- (nullable id)al_JSONObject;

@end

@interface NSString (ALExtension_JSON)

- (nullable id)al_JSONObject;

@end

NS_ASSUME_NONNULL_END
