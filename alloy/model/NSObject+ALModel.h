//
//  NSObject+ALModel.h
//  patchwork
//
//  Created by Alex Lee on 27/06/2017.
//  Copyright © 2017 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (ALModel)
- (nullable instancetype)al_modelCopy;
- (void)al_modelEncodeWithCoder:(NSCoder *)coder;
- (nullable instancetype)al_modelInitWithCoder:(NSCoder *)coder;

- (NSUInteger)al_modelHash;
- (BOOL)al_modelISEquel:(id)model;
- (NSString *)al_modelDescription;
@end

NS_ASSUME_NONNULL_END
