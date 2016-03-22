//
//  RC4.h
//  patchwork
//
//  Created by Alex Lee on 3/22/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (ALExtension_RC4)

- (NSData *)dataByRC4EncryptingWithKey:(NSString *)encryptionKey;

@end

NS_ASSUME_NONNULL_END

