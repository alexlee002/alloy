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

//#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
//
////#elif TARGET_OS_MAC
//
//
//
//
//
//static NSString * const ALSystemOSNameKey       = @"OSName";
//static NSString * const ALSystemOSVersionKey    = @"OSVersion";
//
//@implementation ALDevice {
//    NSDictionary *_deviceInfo;
//}
//
//#pragma mark -
//+ (ALDevice *)currentDevice {
//    static ALDevice *kDevice = nil;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        kDevice = [[ALDevice alloc] init];
//        [kDevice loadDeviceInfo];
//    });
//    return kDevice;
//}
//
//- (void)loadDeviceInfo {
//    NSString *profileCmd = @"system_profiler";
//    NSData *output = [self outputDataForTask:@"/usr/bin/whereis" arguments:@[ profileCmd ]];
//    NSString *cmdPath = [[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding];
//    cmdPath = [cmdPath stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//    if (isEmptyString(cmdPath) || ![[NSFileManager defaultManager] isExecutableFileAtPath:cmdPath]) {
//        ALLogWarn(@"Command: '%@' not found. failed to load device information.", profileCmd);
//        return;
//    }
//    
//    output = [self outputDataForTask:cmdPath arguments:@[ @"SPHardwareDataType", @"SPSoftwareDataType" ]];
//    NSString *outputString = [[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding];
//    if (isEmptyString(outputString)) {
//        ALLogWarn(@"Command: %@ returns empty, failed to load device information.", profileCmd);
//        return;
//    }
//
//    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
//    NSRegularExpression *regex =
//        [NSRegularExpression regularExpressionWithPattern:@"\\s*(.+):\\s+(.+)" options:0 error:nil];
//    [[outputString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]
//        bk_each:^(NSString *_Nonnull str) {
//            NSTextCheckingResult *result = [regex firstMatchInString:str options:0 range:NSMakeRange(0, str.length)];
//            if (result.numberOfRanges > 2) {
//                NSString *key = [[str substringWithRange:[result rangeAtIndex:1]]
//                    stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//                NSString *value = [[str substringWithRange:[result rangeAtIndex:2]]
//                    stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//                dict[key] = value;
//            }
//        }];
//    
//    NSString *osInfo = dict[@"System Version"];
//    if (!isEmptyString(osInfo)) {
//        NSRegularExpression *regex =
//            [NSRegularExpression regularExpressionWithPattern:@"(.+)\\s+(\\d+[\\d\\.]*)(\\s+(\\(.+\\)))?"
//                                                      options:0
//                                                        error:nil];
//        NSTextCheckingResult *result = [regex firstMatchInString:osInfo options:0 range:NSMakeRange(0, osInfo.length)];
//        NSInteger matches = result.numberOfRanges;
//        
//        NSString *value = matches > 1 ? [osInfo substringWithRangeSafety:[result rangeAtIndex:1]]: nil;
//        if (!isEmptyString(value)) {
//            dict[ALSystemOSNameKey] = value;
//        }
//        
//        value = matches > 2 ? [osInfo substringWithRangeSafety:[result rangeAtIndex:2]]: nil;
//        if (!isEmptyString(value)) {
//            dict[ALSystemOSVersionKey] = value;
//        }
//    }
//    _deviceInfo = dict;
//}
//
//- (NSData *)outputDataForTask:(NSString *)command arguments:(nullable NSArray<NSString *> *)args {
//    
//    @try {
//        NSTask *task = [[NSTask alloc] init];
//        [task setLaunchPath:command];
//        if (args != nil) {
//            [task setArguments:args];
//        }
//        
//        NSPipe *outputPipe = [NSPipe pipe];
//        [task setStandardOutput:outputPipe];
//        NSFileHandle *fileHandle = [outputPipe fileHandleForReading];
//        
//        [task launch];
//        [task waitUntilExit];
//        return [fileHandle readDataToEndOfFile];
//    }
//    @catch (NSException *exception) {
//        ALLogWarn(@"Exception: %@", exception);
//        return nil;
//    }
//}
//
//#pragma mark -
//- (nullable NSString *)modelName {
//    return _deviceInfo[@"Model Name"];
//}
//
//- (nullable NSString *)modelIdentifier {
//    return _deviceInfo[@"Model Identifier"];
//}
//
//- (nullable NSString *)systemVersion {
//    return _deviceInfo[ALSystemOSVersionKey];
//}
//
//- (nullable NSString *)systemName {
//    return _deviceInfo[ALSystemOSNameKey];
//}
//
//- (nullable NSString *)name {
//    return _deviceInfo[@"Computer Name"];
//}
//
//- (nullable NSString *)userName {
//    return _deviceInfo[@"User Name"];
//}
//
//- (nullable NSString *)hardwareUUID {
//    return _deviceInfo[@"Hardware UUID"];
//}
//
//- (nullable NSString *)serialNumber {
//    return _deviceInfo[@"Serial Number (system)"];
//}
//
//@end
//
//#endif
