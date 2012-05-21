//
//  PCOAnnouncerWindowController.m
//  Announcer
//
//  Created by Jason Terhorst on 5/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PCOAnnouncerWindowController.h"

@interface PCOAnnouncerWindowController ()

@end

@implementation PCOAnnouncerWindowController

- (id)init;
{
	self = [super init];
	if (self)
	{
		announcerController = [[PCOAnnouncerController alloc] init];
		
		NSMutableDictionary *appDefaults = [NSMutableDictionary dictionary];
		[appDefaults setObject:@"http://announcer.heroku.com/sample_feed.json" forKey:@"feedUrl"];
		[appDefaults setObject:@"http://api.flickr.com/services/feeds/photos_public.gne?id=20901156@N02&lang=en-us&format=rss_200" forKey:@"flickr_feed_url"];
		[appDefaults setObject:[NSNumber numberWithFloat:10.0] forKey:@"seconds_per_picture"];
		[appDefaults setObject:[NSNumber numberWithBool:NO] forKey:@"show_clock"];
		[appDefaults setObject:[NSNumber numberWithBool:YES] forKey:@"show_flickr"];
		
		[[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
	}
	
	return self;
}

- (NSString *)windowNibName;
{
	return @"PCOAnnouncerWindowController";
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
	
	[self announcementsUrlChanged:self];
	[self flickrUrlChanged:self];
	
	[self toggleFlickr:self];
}



- (IBAction)toggleFlickr:(id)sender;
{
	NSLog(@"state: %ld", flickrToggleSwitch.state);
	
	if (flickrToggleSwitch.state > 0)
	{
		flickrSettingsBox.hidden = NO;
	}
	else
	{
		flickrSettingsBox.hidden = YES;
	}
	
	
}



- (IBAction)announcementsUrlChanged:(id)sender;
{
	NSString * feedUrl = announcementsFeedField.stringValue;
	NSLog(@"feed: %@", feedUrl);
	
	if (feedUrl == nil || [feedUrl length] == 0)
	{
		announcementsStatusLabel.stringValue = @"Please enter a valid feed URL";
		return;
	}
	
	[announcementsActivitySpinner startAnimation:sender];
	
	[announcerController loadAnnouncementsFromFeedLocation:feedUrl withCompletionBlock:^{
		
		[announcementsActivitySpinner stopAnimation:sender];
		
		announcementsStatusLabel.stringValue = [NSString stringWithFormat:@"Feed is ready. Found %d announcements", [announcerController.announcements count]];
		
	} andErrorBlock:^(NSError * error) {
		NSLog(@"error: %@", [error localizedDescription]);
		
		[announcementsActivitySpinner stopAnimation:sender];
		
		announcementsStatusLabel.stringValue = @"Failed trying to update announcements";
		
	}];
}


- (IBAction)flickrUrlChanged:(id)sender;
{
	NSString * feedUrl = flickrFeedField.stringValue;
	NSLog(@"feed: %@", feedUrl);
	
	if (feedUrl == nil || [feedUrl length] == 0)
	{
		flickrStatusLabel.stringValue = @"Please enter a valid feed URL";
		return;
	}
	
	[flickrActivitySpinner startAnimation:sender];
	
	[announcerController loadFlickrFeedFromLocation:feedUrl withCompletionBlock:^{
		
		[flickrActivitySpinner stopAnimation:sender];
		
		flickrStatusLabel.stringValue = [NSString stringWithFormat:@"Feed is ready. Found %d images", [announcerController.flickrImageUrls count]];
		
	} andErrorBlock:^(NSError * error) {
		NSLog(@"error: %@", [error localizedDescription]);
		
		[flickrActivitySpinner stopAnimation:sender];
		
		flickrStatusLabel.stringValue = @"Failed trying to update Flickr feed";
		
	}];
}



- (IBAction)startSlideshow:(id)sender;
{
	NSLog(@"found %lu announcements to show.", [[announcerController currentAnnouncements] count]);
	
	announcementsWindow = [[NSWindow alloc] initWithContentRect:[[NSScreen mainScreen] frame] styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO screen:[NSScreen mainScreen]];
	[announcementsWindow setLevel:NSScreenSaverWindowLevel];
	[announcementsWindow setBackgroundColor:[NSColor blackColor]];
	
	[announcementsWindow orderFront:self];
	
	[NSCursor setHiddenUntilMouseMoves:YES];
}


@end
