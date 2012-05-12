//
//  PCOAppDelegate.m
//  Announcer Mac
//
//  Created by Jason Terhorst on 5/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PCOAppDelegate.h"

@implementation PCOAppDelegate

@synthesize window = _window;
@synthesize mainUIKitView;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
	
	announcerController = [[PCOAnnouncerController alloc] init];
	
	[self.mainUIKitView UIWindow].rootViewController = [announcerController viewController];
	
	
}

@end
