//
//  NSObject+JSONTransform.h
//  patchwork
//
//  Created by Alex Lee on 3/24/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (JSONTransform)

- (nullable NSString *)JSONString;
- (nullable NSData *)JSONData;

- (nullable id)objectFromJSONString:(NSString *)string;
- (nullable id)objectFromJSONData:(NSData *)data;

@end

@interface NSData (JSONTransform)

- (nullable id)JSONObject;

@end

@interface NSString (JSONTransform)

- (nullable id)JSONObject;

@end

NS_ASSUME_NONNULL_END
