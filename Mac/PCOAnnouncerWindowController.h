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

@interface PCOAnnouncerWindowController : NSWindowController <PCOControlResponseWindowDelegate, NSWindowDelegate, PCOAnnouncerControllerDelegate>
{
	PCOAnnouncerController * announcerController;

	IBOutlet NSTextField * announcementsFeedField;

	IBOutlet NSProgressIndicator * announcementsActivitySpinner;

	IBOutlet NSTextField * announcementsStatusLabel;
	
	
	PCOControlResponseWindow * announcementsWindow;
	
	QTMovieLayer * backgroundLayer;
	
	CATextLayer * titleLayer;
	CATextLayer * bodyLayer;
	
	CATextLayer * clockLayer;
	
	CATextLayer * bigClockLayer;
	

	PCOControlResponseWindow * flickrWindow;
	QTMovieLayer * flickrLayer;
}

//- (IBAction)toggleFlickr:(id)sender;

- (IBAction)announcementsUrlChanged:(id)sender;

//- (IBAction)flickrUrlChanged:(id)sender;


- (IBAction)startSlideshow:(id)sender;

@end
