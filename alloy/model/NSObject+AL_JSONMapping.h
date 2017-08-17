//
//  NSObject+JSONMapping.h
//  patchwork
//
//  Created by Alex Lee on 09/06/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//
//  IMPORTANT:
//  The implementation of JSON & model mapping is very much inspired by YYModel(@link: https://github.com/ibireme/YYModel ).
//  Thanks @Yaoyuan (@link: https://github.com/ibireme )!
//  The copyright of the code from YYModel is reserved by @Yaoyuan.
//
//  What's different with YYModel:
//      - (nullable id)al_modelCopy;
//      - (void)al_modelEncodeWithCoder:(NSCoder *)coder;
//      - (nullable id)al_modelInitWithCoder:(NSCoder *)coder;
//  In YYModel, these methods process the property filter by whitelist & blacklist.
//  In ALModel, all property that can set value via setter or setValueForKey: will be processed.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface NSObject (AL_JSONMapping)

#pragma mark - model & json mapping (@ref: YYModel)
+ (nullable instancetype)al_modelWithJSON:(id)JSON;
+ (nullable instancetype)al_modelWithDictionary:(NSDictionary *)dict;
- (BOOL)al_modelSetWithJSON:(id)json;
- (BOOL)al_modelSetWithDictionary:(NSDictionary *)dic;

- (nullable __kindof id)al_modelToJSONObject;
- (nullable NSData *)al_modelToJSONData;
- (nullable NSString *)al_modelToJSONString;

@end
NS_ASSUME_NONNULL_END
