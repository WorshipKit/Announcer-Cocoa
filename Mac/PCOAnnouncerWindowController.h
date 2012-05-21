//
//  PCOAnnouncerWindowController.h
//  Announcer
//
//  Created by Jason Terhorst on 5/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "PCOAnnouncerController.h"

@interface PCOAnnouncerWindowController : NSWindowController
{
	PCOAnnouncerController * announcerController;
	
	IBOutlet NSBox * flickrSettingsBox;
	
	IBOutlet NSTextField * announcementsFeedField;
	IBOutlet NSTextField * flickrFeedField;
	
	IBOutlet NSProgressIndicator * announcementsActivitySpinner;
	IBOutlet NSProgressIndicator * flickrActivitySpinner;
	
	IBOutlet NSTextField * announcementsStatusLabel;
	IBOutlet NSTextField * flickrStatusLabel;
	
	IBOutlet NSButton * flickrToggleSwitch;
	
	
	NSWindow * announcementsWindow;
}

- (IBAction)toggleFlickr:(id)sender;

- (IBAction)announcementsUrlChanged:(id)sender;

- (IBAction)flickrUrlChanged:(id)sender;


- (IBAction)startSlideshow:(id)sender;

@end
