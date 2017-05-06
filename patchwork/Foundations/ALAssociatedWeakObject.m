//
//  ALAssociatedWeakObject.m
//  MCLog
//
//  Created by Alex Lee on 1/9/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALAssociatedWeakObject.h"
#import <objc/runtime.h>
#import "ALUtilitiesHeader.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^deallocBlock)(void);

@interface ALAssociatedWeakObject : NSObject

+ (instancetype)weakAssociatedObjectWithDeallocCallback:(deallocBlock)block;

@end

@implementation ALAssociatedWeakObject {
    deallocBlock _block;
}

+ (instancetype)weakAssociatedObjectWithDeallocCallback:(deallocBlock)block {
    return [[self alloc] initWithDeallocCallback:block];
}

- (instancetype)initWithDeallocCallback:(deallocBlock)block {
    self = [super init];
    if (self) {
        _block = [block copy];
    }
    return self;
}

- (void)dealloc {
    if (_block) {
        _block();
    }
}

@end


@implementation NSObject (AssociatedWeakObject)

- (void)runAtDealloc:(void(^)(void))block {
    static const char kRunAtDeallocBlockKey;
    if (block) {
        ALAssociatedWeakObject *proxy = [ALAssociatedWeakObject weakAssociatedObjectWithDeallocCallback:block];
        objc_setAssociatedObject(self,
                                 &kRunAtDeallocBlockKey,
                                 proxy,
                                 OBJC_ASSOCIATION_RETAIN);
    }
}


- (void)setWeakAssociatedPropertyValue:(nullable NSObject *)value withAssociatedKey:(const void *)key {
    objc_setAssociatedObject(self, key, value, OBJC_ASSOCIATION_ASSIGN);
    al_weakify(self);
    [value runAtDealloc:^{
        al_strongify(self);
        objc_setAssociatedObject(self, key, nil, OBJC_ASSOCIATION_ASSIGN);
    }];
}

@end

NS_ASSUME_NONNULL_END
