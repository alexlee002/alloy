//
//  ALDBStatement+orm.m
//  alloy
//
//  Created by Alex Lee on 11/10/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import "ALDBStatement+orm_Private.h"
#import "ALModelSelect.h"
#import <objc/runtime.h>

@implementation ALDBStatement (orm)

- (nullable NSEnumerator *)objectEnumerator {
    return [self.modelSelect objectEnumerator];
}

- (nullable NSArray *)allObjects {
    return [self.modelSelect allObjects];
}

- (void)setModelSelect:(ALModelSelect *)modelSelect {
    objc_setAssociatedObject(self, @selector(modelSelect), modelSelect, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (ALModelSelect *)modelSelect {
    return objc_getAssociatedObject(self, @selector(modelSelect));
}

@end
