//
//  MD5.h
//  Pods
//
//  Created by Alex Lee on 3/14/16.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (ALExtension_MD5)

- (NSString *)MD5;

@end

@interface NSString (ALExtension_MD5)

- (NSString *)MD5;

@end

extern NSString *_Nullable fileMD5Hash(NSString *filepath);

NS_ASSUME_NONNULL_END
