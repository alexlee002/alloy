//
//  ALDevice.h
//  Pods
//
//  Created by Alex Lee on 3/14/16.
//
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR

@compatibility_alias ALDevice UIDevice;

#elif TARGET_OS_MAC

NS_ASSUME_NONNULL_BEGIN
@interface ALDevice : NSObject

+ (ALDevice *)currentDevice;

@property(readonly, nullable) NSString *modelName;
@property(readonly, nullable) NSString *modelIdentifier;
@property(readonly, nullable) NSString *systemVersion;
@property(readonly, nullable) NSString *systemName;
@property(readonly, nullable) NSString *name;
@property(readonly, nullable) NSString *userName;
@property(readonly, nullable) NSString *hardwareUUID;
@property(readonly, nullable) NSString *serialNumber;

@end

NS_ASSUME_NONNULL_END
#endif