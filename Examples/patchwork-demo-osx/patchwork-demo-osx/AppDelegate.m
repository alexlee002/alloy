//
//  AppDelegate.m
//  patchwork-demo-osx
//
//  Created by Alex Lee on 16/10/11.
//  Copyright © 2016年 me.alexlee002. All rights reserved.
//

#import "AppDelegate.h"
#import "patchwork.h"


@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    ALLogInfo(@"infoDict: %@", [[NSBundle mainBundle] infoDictionary]);
    ALLogInfo(@"version: %@", [NSBundle mainBundle].version);
    ALLogInfo(@"build version: %@", [NSBundle mainBundle].buildVersion);
    ALLogInfo(@"name: %@", [NSBundle mainBundle].name);
    ALLogInfo(@"display name: %@", [NSBundle mainBundle].displayName);
    
    ALLogInfo(@"device name: %@", [ALDevice currentDevice].name);
    ALLogInfo(@"device model: %@", [ALDevice currentDevice].model);
    ALLogInfo(@"OS name: %@", [ALDevice currentDevice].systemName);
    ALLogInfo(@"OS ver: %@", [ALDevice currentDevice].systemVersion);
    ALLogInfo(@"device uuid: %@", [ALDevice currentDevice].hardwareUUID);
    ALLogInfo(@"device searial: %@", [ALDevice currentDevice].serialNumber);
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
