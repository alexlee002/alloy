//
//  NSBundle+BundleInfo.h
//  patchwork
//
//  Created by Alex Lee on 16/12/2016.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSBundle (BundleInfo)

@property(readonly) NSString *version;
@property(readonly) NSString *buildVersion;
@property(readonly) NSString *displayName;
@property(readonly) NSString *name;

@end
NS_ASSUME_NONNULL_END
