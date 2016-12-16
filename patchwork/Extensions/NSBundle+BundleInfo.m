//
//  NSBundle+BundleInfo.m
//  patchwork
//
//  Created by Alex Lee on 16/12/2016.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "NSBundle+BundleInfo.h"

@implementation NSBundle (BundleInfo)

- (NSString *)version {
    return [self infoDictionary][@"CFBundleShortVersionString"];
}

- (NSString *)buildVersion {
    return [self infoDictionary][@"CFBundleVersion"];
}

- (NSString *)displayName {
    return [self infoDictionary][@"CFBundleDisplayName"] ?: self.name;
}

- (NSString *)name {
    return [self infoDictionary][@"CFBundleName"];
}

@end
