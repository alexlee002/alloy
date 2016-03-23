//
//  AppDelegate.m
//  patchwork-Demo-OSX
//
//  Created by Alex Lee on 3/17/16.
//  Copyright © 2016 me.alexlee002. All rights reserved.
//

#import "AppDelegate.h"
#import <patchwork.h>

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    [HHTimer scheduledTimerWithTimeInterval:3 dispatchQueue:dispatch_get_main_queue() block:^{
        NSLog(@"====== HHTimer test ======");
    } userInfo:nil repeats:NO];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
