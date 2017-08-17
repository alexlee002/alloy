//
//  __ALModelMeta+JSONMapping.h
//  patchwork
//
//  Created by Alex Lee on 22/06/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "__ALModelMeta.h"

NS_ASSUME_NONNULL_BEGIN

@interface _ALPropertyJSONMeta : NSObject {
    @package
    _ALModelPropertyMeta    *_meta;
    Class _Nullable         _genericClass;      // container's generic class.
    /*
     property->key:     _mappedToKey:key      _mappedToKeyPath:nil              _mappedToKeyArray:nil
     property->keyPath: _mappedToKey:keyPath  _mappedToKeyPath:keyPath(array)   _mappedToKeyArray:nil
     property->keys:    _mappedToKey:keys[0]  _mappedToKeyPath:nil/keyPath      _mappedToKeyArray:keys(array)
     */
    NSString *_Nullable     _mappedToKey;       // the json key that property mapped to.
    NSArray *_Nullable      _mappedToKeyPath;   // the json keyPath that property mapped to (nil if it's not a keypath).
    NSArray *_Nullable      _mappedToKeyArray;  // the key(NSString) or keyPath(NSArray) array (nil if not mapped to multiple keys).
    BOOL                    _hasCustomClassFromDictionary; //customize result model class from JSON; @see:"+modelCustomClassForDictionary:"
    _ALPropertyJSONMeta *_Nullable  _next;     // next meta if there are multiple properties mapped to the same key.
}

+ (instancetype)metaWithPropertyMeta:(_ALModelPropertyMeta *)meta genericClass:(Class)generic;
@end


@interface _ALModelJSONMeta : NSObject {
    @package
    _ALModelMeta    *_meta;
    
    //@{mappedKey/keypath: _ALModelPropertyMeta}
    NSDictionary<NSString *, _ALPropertyJSONMeta *> *_Nullable _mapper;
    
    NSArray<_ALPropertyJSONMeta *> *_Nullable                  _allPropertyMetas;
    //properties mapped to json keypath
    NSArray<_ALPropertyJSONMeta *> *_Nullable                  _keyPathPropertyMetas;
    //properties mapped to json keys
    NSArray<_ALPropertyJSONMeta *> *_Nullable                  _multiKeysPropertyMetas;
    
    BOOL _hasCustomWillTransformFromDictionary;
    BOOL _hasCustomTransformFromDictionary;
    BOOL _hasCustomTransformToDictionary;
    BOOL _hasCustomClassFromDictionary;
}

+ (instancetype)metaWithClass:(Class)cls;
+ (instancetype)metaWithModelMeta:(_ALModelMeta *)meta;
@end

NS_ASSUME_NONNULL_END
