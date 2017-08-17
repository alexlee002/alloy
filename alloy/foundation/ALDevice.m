//
//  ALDevice.m
//  Pods
//
//  Created by Alex Lee on 3/14/16.
//
//


#import "ALDevice.h"
#import "ALLogger.h"

#if TARGET_OS_MAC && !(TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR)
#import <sys/sysctl.h>
@import IOKit;
@import SystemConfiguration;

@implementation ALDevice

@synthesize name = _computerName;
@synthesize model = _modelIdentifier;
@synthesize systemName = _systemName;
@synthesize systemVersion = _systemVersion;
@synthesize systemVersionString = _systemVersionString;
@synthesize hardwareUUID = _hardwareUUID;
@synthesize serialNumber = _searialNumber;


+ (instancetype)currentDevice {
    static ALDevice *kDevice = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kDevice = [[ALDevice alloc] init];
        [kDevice loadDeviceInfo];
    });
    return kDevice;

}

- (void)loadDeviceInfo {
    {
        CFStringRef strref = SCDynamicStoreCopyComputerName(NULL, NULL);
        _computerName = (__bridge_transfer NSString *)strref;
    }
    
    {
        int mib[2];
        size_t len = 0;
        char *cstr = NULL;
        
        mib[0] = CTL_HW;
        mib[1] = HW_MODEL;
        sysctl( mib, 2, NULL, &len, NULL, 0 );
        cstr = malloc( len );
        sysctl( mib, 2, cstr, &len, NULL, 0 );
        _modelIdentifier = [NSString stringWithUTF8String:cstr];
        free( cstr );
    }
    
    {
        NSProcessInfo *processInfo = [NSProcessInfo processInfo];
        _systemVersionString = processInfo.operatingSystemVersionString;

        NSOperatingSystemVersion sysver = processInfo.operatingSystemVersion;
        _systemVersion = [NSString stringWithFormat:@"%d.%d.%d",
                          (int)sysver.majorVersion,
                          (int)sysver.minorVersion,
                          (int)sysver.patchVersion];
        _systemName = [self OSNameWithVersion:sysver];
    }
    
    {
        io_service_t platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault,
                                                                  IOServiceMatching("IOPlatformExpertDevice"));
        if (platformExpert) {
            CFStringRef strref = IORegistryEntryCreateCFProperty(platformExpert,
                                                                 CFSTR(kIOPlatformSerialNumberKey),
                                                                 kCFAllocatorDefault, 0);
            _searialNumber = (__bridge_transfer NSString *)strref;
            
            strref = IORegistryEntryCreateCFProperty(platformExpert,
                                                     CFSTR(kIOPlatformUUIDKey),
                                                     kCFAllocatorDefault, 0);
            _hardwareUUID = (__bridge_transfer NSString *)strref;
            
            IOObjectRelease(platformExpert);
        }
    }
    
}

- (NSString *)OSNameWithVersion:(NSOperatingSystemVersion)ver {
    return ver.majorVersion >= 12 ? @"macOS" : @"Mac OS X";
}

@end

#endif
