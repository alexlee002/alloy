//
//  DES.h
//  patchwork
//
//  Created by Alex Lee on 3/22/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (ALExtension_DES)

- (nullable NSData *)al_dataByDESEncryptingWithKey:(NSData *)key;
- (NSData *)al_dataByDESDecryptingWithKey:(NSData *)key;

@end
NS_ASSUME_NONNULL_END
