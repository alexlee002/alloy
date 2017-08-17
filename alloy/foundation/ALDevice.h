//
//  ALDevice.h
//  Pods
//
//  Created by Alex Lee on 3/14/16.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#if (TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR)
@import UIKit;
@compatibility_alias ALDevice UIDevice;

#elif TARGET_OS_MAC
@interface ALDevice : NSObject

+ (instancetype)currentDevice;
// keep the same name with iOS
@property(nonatomic,readonly,strong) NSString    *name;              // e.g. "My iPhone" or "Alex's MacBook Pro"
@property(nonatomic,readonly,strong) NSString    *model;             // e.g. @"iPhone", @"iPod touch", "MacBookPro11,1"
//@property(nonatomic,readonly,strong) NSString    *localizedModel;    // localized version of model
@property(nonatomic,readonly,strong) NSString    *systemName;        // e.g. @"iOS" or "Mac OS X"
@property(nonatomic,readonly,strong) NSString    *systemVersion;     // e.g. @"4.0" or "10.12.1"

// only OS X
//@property(readonly, nullable) NSString *userName;
@property(readonly, nullable) NSString *hardwareUUID;
@property(readonly, nullable) NSString *serialNumber;
@property(readonly)           NSString *systemVersionString; //eg: "10.12.1 (Build 16B2555)"

@end

#endif

NS_ASSUME_NONNULL_END
