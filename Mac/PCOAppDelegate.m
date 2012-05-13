//
//  PCOAppDelegate.m
//  Announcer Mac
//
//  Created by Jason Terhorst on 5/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PCOAppDelegate.h"

@implementation PCOAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
	
	announcerController = [[PCOAnnouncerWindowController alloc] init];
	[announcerController showWindow:self];
}

@end
