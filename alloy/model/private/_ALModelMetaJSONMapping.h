//
//  _ALModelMeta+JSONMapping.h
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

#import "_ALModelMeta.h"

NS_ASSUME_NONNULL_BEGIN
@interface _ALModelPropertyJSONMapping : NSObject {
  @package
    _ALModelPropertyMeta   *_meta;
    Class                   _genericClass;  // container's generic class.
    
    /*
     property->key:     _mappedToKey:key      _mappedToKeyPath:nil              _mappedToKeyArray:nil
     property->keyPath: _mappedToKey:keyPath  _mappedToKeyPath:keyPath(array)   _mappedToKeyArray:nil
     property->keys:    _mappedToKey:keys[0]  _mappedToKeyPath:nil/keyPath      _mappedToKeyArray:keys(array)
     */
    NSString *_Nullable     _mappedToKey;       // the json key that property mapped to.
    NSArray *_Nullable      _mappedToKeyPath;   // the json keyPath that property mapped to (nil if it's not a keypath).
    NSArray *_Nullable      _mappedToKeyArray;  // the key(NSString) or keyPath(NSArray) array (nil if not mapped to multiple keys).
    BOOL                    _hasCustomClassFromDictionary; //customize result model class from JSON; @see:"+modelCustomClassForDictionary:"
    _ALModelPropertyJSONMapping *_Nullable  _next;
}

+ (instancetype)mappingWithPropertyMeta:(_ALModelPropertyMeta *)meta genericClass:(Class)generic;

@end

@interface _ALModelJSONMapping : NSObject {
  @package
    _ALModelMeta           *_meta;
    
    //@{mappedKey/keypath: _ALModelPropertyMeta}
    NSDictionary<NSString *, _ALModelPropertyJSONMapping *> *_Nullable  _mapper;
    
    NSArray<_ALModelPropertyJSONMapping *> *_Nullable                   _allPropertyMetas;
    //properties mapped to json keypath
    NSArray<_ALModelPropertyJSONMapping *> *_Nullable                   _keyPathPropertyMetas;
    //properties mapped to json keys
    NSArray<_ALModelPropertyJSONMapping *> *_Nullable                   _multiKeysPropertyMetas;
    
    BOOL _hasCustomWillTransformFromDictionary;
    BOOL _hasCustomTransformFromDictionary;
    BOOL _hasCustomTransformToDictionary;
    BOOL _hasCustomClassFromDictionary;
}

+ (instancetype)mappingWithClass:(Class)cls;
+ (instancetype)mappingWithModelMeta:(_ALModelMeta *)meta;

@end

NS_ASSUME_NONNULL_END
