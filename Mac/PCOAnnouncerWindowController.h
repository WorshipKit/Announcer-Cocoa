//
//  PCOAnnouncerWindowController.h
//  Announcer
//
//  Created by Jason Terhorst on 5/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>

#import <Quartz/Quartz.h>
#import <QuartzCore/QuartzCore.h>
#import <QTKit/QTKit.h>

#import "PCOAnnouncerController.h"

#import "PCOControlResponseWindow.h"

@interface PCOAnnouncerWindowController : NSWindowController <PCOControlResponseWindowDelegate, NSWindowDelegate>
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
	
	
	
	NSInteger currentSlideIndex;
	
	PCOControlResponseWindow * announcementsWindow;
	
	QTMovieLayer * backgroundLayer;
	
	CATextLayer * titleLayer;
	CATextLayer * bodyLayer;
	
	CATextLayer * clockLayer;
	
	NSTimer * clockTimer;
	NSTimer * slideTimer;
	
	
	NSInteger currentFlickrIndex;
	NSTimer * flickrTimer;
	PCOControlResponseWindow * flickrWindow;
	QTMovieLayer * flickrLayer;
}

- (IBAction)toggleFlickr:(id)sender;

- (IBAction)announcementsUrlChanged:(id)sender;

- (IBAction)flickrUrlChanged:(id)sender;


- (IBAction)startSlideshow:(id)sender;

@end
