//
//  AppDelegate.m
//  WordCounterHelper
//
//  Created by Rares Tamas on 3/31/15.
//  Copyright (c) 2015 Rares Tamas. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    NSString *path = [[[[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent]stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
    
    [[NSWorkspace sharedWorkspace] launchApplication:path];
    [NSApp terminate: nil];
}



- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}



@end
