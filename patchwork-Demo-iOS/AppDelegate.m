//
//  AppDelegate.m
//  patchwork-Demo-iOS
//
//  Created by Alex Lee on 2/23/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "AppDelegate.h"
#import <objc/runtime.h>

@interface GCDSyncTest : NSObject

- (void)syncTest:(dispatch_block_t)block callerThread:(NSThread *)th;

@end

static const void * const kDispatchQueueSpecificKey = &kDispatchQueueSpecificKey;
@implementation GCDSyncTest {
    dispatch_queue_t _queue;
}

- (instancetype)init {
    if (self = [super init]) {
        _queue = dispatch_queue_create([[NSString stringWithFormat:@"test_case.%@", self] UTF8String], NULL);
        dispatch_queue_set_specific(_queue, kDispatchQueueSpecificKey, (__bridge void *)self, NULL);
    }
    return self;
}

- (void)safelyRun:(dispatch_block_t)block {
    GCDSyncTest *currentSyncQueue = (__bridge id)dispatch_get_specific(kDispatchQueueSpecificKey);
    if (currentSyncQueue == self) {
        NSLog(@"!!! ALFMDatabaseQueue was called reentrantly on the same queue, which would lead to a deadlock.");
        block();
    } else {
        dispatch_sync(_queue, ^{
            block();
        });
    }
}

- (void)syncTest:(dispatch_block_t)block callerThread:(NSThread *)th{
    [self safelyRun:block];
//    //    GCDSyncTest *currentSyncQueue = (__bridge id)dispatch_get_specific(kDispatchQueueSpecificKey);
//    //    NSAssert(currentSyncQueue != self, @"maybe deadlock!");
//    
//    NSLog(@">>> caller: %@", th);
//    dispatch_sync(_queue, ^{
//        block();
//    });
    
}

@end

@interface TestCase1 : NSObject

- (void)instanceMethod;
+ (void)classMethod;

@end

@implementation TestCase1

- (void)instanceMethod {}
+ (void)classMethod {}

@end

@interface TestCase1_1 : TestCase1
@end

@implementation TestCase1_1
@end

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    self.window.rootViewController = [[UIViewController alloc] init];
    

    //[self syncTest];
    
    if ([TestCase1 respondsToSelector:@selector(instanceMethod)]) {
        NSLog(@"class responds to instanceMethod");
    }
    
    if ([TestCase1 respondsToSelector:@selector(classMethod)]) {
        NSLog(@"class responds to classMethod");
    }
    
    if ([TestCase1 instancesRespondToSelector:@selector(instanceMethod)]) {
        NSLog(@"class instancesRespond to instanceMethod");
    }
    
    if ([TestCase1 instancesRespondToSelector:@selector(classMethod)]) {
        NSLog(@"class instancesRespond to classMethod");
    }
    
    Class cls = [TestCase1 class];
    NSLog(@"cls is metaclass: %@", @(class_isMetaClass(cls)));
    if ([cls respondsToSelector:@selector(instanceMethod)]) {
        NSLog(@"cls responds to instanceMethod");
    }
    
    if ([cls respondsToSelector:@selector(classMethod)]) {
        NSLog(@"cls responds to classMethod");
    }
    
    if ([cls instancesRespondToSelector:@selector(instanceMethod)]) {
        NSLog(@"cls instancesRespond to instanceMethod");
    }
    
    if ([cls instancesRespondToSelector:@selector(classMethod)]) {
        NSLog(@"cls instancesRespond to classMethod");
    }
    
    if (class_respondsToSelector(cls, @selector(instanceMethod))) {
        NSLog(@"cls class_respondsToSelector instanceMethod");
    }
    if (class_respondsToSelector(cls, @selector(classMethod))) {
        NSLog(@"cls class_respondsToSelector classMethod");
    }
    
    TestCase1 *t = [[TestCase1 alloc] init];
    if ([t respondsToSelector:@selector(instanceMethod)]) {
        NSLog(@"instance responds to instanceMethod");
    }
    
    if ([t respondsToSelector:@selector(classMethod)]) {
        NSLog(@"instance responds to classMethod");
    }
    
    if ([t.class instancesRespondToSelector:@selector(instanceMethod)]) {
        NSLog(@"instance.class instancesRespond to instanceMethod");
    }
    
    if ([t.class instancesRespondToSelector:@selector(classMethod)]) {
        NSLog(@"instance.class instancesRespond to classMethod");
    }
    
    if ([t.class respondsToSelector:@selector(instanceMethod)]) {
        NSLog(@"instance.class responds to instanceMethod");
    }
    
    if ([t.class respondsToSelector:@selector(classMethod)]) {
        NSLog(@"instance.class responds to classMethod");
    }
    
    if (class_respondsToSelector(t.class, @selector(instanceMethod))) {
        NSLog(@"instance.class class_respondsToSelector instanceMethod");
    }
    if (class_respondsToSelector(t.class, @selector(classMethod))) {
        NSLog(@"instance.class class_respondsToSelector classMethod");
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////////
    
    if ([TestCase1_1 respondsToSelector:@selector(instanceMethod)]) {
        NSLog(@"subclass responds to instanceMethod");
    }
    
    if ([TestCase1_1 respondsToSelector:@selector(classMethod)]) {
        NSLog(@"subclass responds to classMethod");
    }
    
    if ([TestCase1_1 instancesRespondToSelector:@selector(instanceMethod)]) {
        NSLog(@"subclass instancesRespond to instanceMethod");
    }
    
    if ([TestCase1_1 instancesRespondToSelector:@selector(classMethod)]) {
        NSLog(@"subclass instancesRespond to classMethod");
    }
    
    cls = [TestCase1_1 class];
    if ([cls respondsToSelector:@selector(instanceMethod)]) {
        NSLog(@"subcls responds to instanceMethod");
    }
    
    if ([cls respondsToSelector:@selector(classMethod)]) {
        NSLog(@"subcls responds to classMethod");
    }
    
    if ([cls instancesRespondToSelector:@selector(instanceMethod)]) {
        NSLog(@"subcls instancesRespond to instanceMethod");
    }
    
    if ([cls instancesRespondToSelector:@selector(classMethod)]) {
        NSLog(@"subcls instancesRespond to classMethod");
    }
    
    if (class_respondsToSelector(cls, @selector(instanceMethod))) {
        NSLog(@"subcls class_respondsToSelector instanceMethod");
    }
    if (class_respondsToSelector(cls, @selector(classMethod))) {
        NSLog(@"subcls class_respondsToSelector classMethod");
    }
    
    t = [[TestCase1_1 alloc] init];
    if ([t respondsToSelector:@selector(instanceMethod)]) {
        NSLog(@"sub instance responds to instanceMethod");
    }
    
    if ([t respondsToSelector:@selector(classMethod)]) {
        NSLog(@"sub instance responds to classMethod");
    }
    
    if ([t.class instancesRespondToSelector:@selector(instanceMethod)]) {
        NSLog(@"sub instance.class instancesRespond to instanceMethod");
    }
    
    if ([t.class instancesRespondToSelector:@selector(classMethod)]) {
        NSLog(@"sub instance.class instancesRespond to classMethod");
    }
    
    if ([t.class respondsToSelector:@selector(instanceMethod)]) {
        NSLog(@"sub instance.class responds to instanceMethod");
    }
    
    if ([t.class respondsToSelector:@selector(classMethod)]) {
        NSLog(@"sub instance.class responds to classMethod");
    }
    
    if (class_respondsToSelector(t.class, @selector(instanceMethod))) {
        NSLog(@"sub instance.class class_respondsToSelector instanceMethod");
    }
    if (class_respondsToSelector(t.class, @selector(classMethod))) {
        NSLog(@"sub instance.class class_respondsToSelector classMethod");
    }
    
    return YES;
}

- (void)syncTest {
    GCDSyncTest *t = [[GCDSyncTest alloc] init];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"==== main thread 1 ====");
        [t syncTest:^{
            for (NSInteger i = 0; i < 10; ++i) {
                [NSThread sleepForTimeInterval:1.f];
                NSLog(@"==== main thread 1: %zd", i);
            }
            [t syncTest:^{
                for (int i = 0; i < 5; ++i) {
                    [NSThread sleepForTimeInterval:1.f];
                    NSLog(@"---- main thread 1 nested: %zd", i);
                }
            } callerThread:nil];
        } callerThread:nil];
    });
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"==== main thread 2 ====");
        [t syncTest:^{
            for (NSInteger i = 0; i < 10; ++i) {
                [NSThread sleepForTimeInterval:1.f];
                NSLog(@"==== main thread 2: %zd", i);
            }
        } callerThread:nil];
    });
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"==== main thread 3 ====");
        [t syncTest:^{
            for (NSInteger i = 0; i < 10; ++i) {
                [NSThread sleepForTimeInterval:1.f];
                NSLog(@"==== main thread 3: %zd", i);
            }
            [t syncTest:^{
                for (int i = 0; i < 5; ++i) {
                    [NSThread sleepForTimeInterval:1.f];
                    NSLog(@"---- main thread 3 nested: %zd", i);
                }
            } callerThread:nil];
        } callerThread:nil];
    });
    
    NSLog(@"---- main thread ----");
    [t syncTest:^{
        for (NSInteger i = 0; i < 10; ++i) {
            [NSThread sleepForTimeInterval:1.f];
            NSLog(@"---- main thread: %zd", i);
            
            [t syncTest:^{
                for (int i = 0; i < 2; ++i) {
                    [NSThread sleepForTimeInterval:1.f];
                    NSLog(@"---- main thread nested: %zd", i);
                }
            } callerThread:nil];
        }
    } callerThread:nil];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
