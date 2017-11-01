//
//  NSObject+AL_JSONMapping.h
//  alloy
//
//  Created by Alex Lee on 06/10/2017.
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

+ (nullable NSArray *)al_modelArrayWithJSON:(id)json;
+ (nullable NSDictionary *)al_modelDictionaryWithJSON:(id)json;

- (nullable __kindof id)al_modelToJSONObject;
- (nullable NSData *)al_modelToJSONData;
- (nullable NSString *)al_modelToJSONString;

@end


/**
 Provide some data-model method for NSArray.
 */
@interface NSArray (AL_JSONMapping)

/**
 Creates and returns an array from a json-array.
 This method is thread-safe.
 
 @param cls  The instance's class in array.
 @param json  A json array of `NSArray`, `NSString` or `NSData`.
 Example: [{"name":"Mary"},{name:"Joe"}]
 
 @return A array, or nil if an error occurs.
 */
+ (nullable NSArray *)al_modelArrayWithClass:(Class)cls JSON:(id)json;

@end



/**
 Provide some data-model method for NSDictionary.
 */
@interface NSDictionary (AL_JSONMapping)

/**
 Creates and returns a dictionary from a json.
 This method is thread-safe.
 
 @param cls  The value instance's class in dictionary.
 @param json  A json dictionary of `NSDictionary`, `NSString` or `NSData`.
 Example: {"user1":{"name","Mary"}, "user2": {name:"Joe"}}
 
 @return A dictionary, or nil if an error occurs.
 */
+ (nullable NSDictionary *)al_modelDictionaryWithClass:(Class)cls JSON:(id)json;
@end
NS_ASSUME_NONNULL_END
