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
		announcerController.delegate = self;
		
		NSMutableDictionary *appDefaults = [NSMutableDictionary dictionary];
		[appDefaults setObject:@"2" forKey:@"campusId"];
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
	//[self flickrUrlChanged:self];
	
	//[self toggleFlickr:self];

	if ([[NSUserDefaults standardUserDefaults] valueForKey:@"campusId"])
	{
		[self startSlideshow:nil];

		[self nextSlide];
	}
}


/*
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
*/


- (IBAction)announcementsUrlChanged:(id)sender;
{
	NSString * feedUrl = [NSString stringWithFormat:@"http://announcer.heroku.com/feeds/%@.json", announcementsFeedField.stringValue];
	NSLog(@"feed: %@", feedUrl);
	
	if (feedUrl == nil || [feedUrl length] == 0)
	{
		announcementsStatusLabel.stringValue = @"Please enter a valid feed URL";
		return;
	}
	
	[announcementsActivitySpinner startAnimation:sender];

	announcerController.announcementsFeedUrl = feedUrl;

	[announcerController loadAnnouncementsWithCompletionBlock:^{
		
		[announcementsActivitySpinner stopAnimation:sender];
		
		announcementsStatusLabel.stringValue = [NSString stringWithFormat:@"Feed is ready. Found %ld announcements", [announcerController.announcements count]];

		if (announcementsWindow)
		{
			[self nextSlide];
		}

	} andErrorBlock:^(NSError * error) {
		NSLog(@"error: %@", [error localizedDescription]);
		
		[announcementsActivitySpinner stopAnimation:sender];
		
		announcementsStatusLabel.stringValue = @"Failed trying to update announcements";
		
	}];
}


/*
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
		
		flickrStatusLabel.stringValue = [NSString stringWithFormat:@"Feed is ready. Found %ld images", [announcerController.flickrImageUrls count]];
		
	} andErrorBlock:^(NSError * error) {
		NSLog(@"error: %@", [error localizedDescription]);
		
		[flickrActivitySpinner stopAnimation:sender];
		
		flickrStatusLabel.stringValue = @"Failed trying to update Flickr feed";
		
	}];
}
*/


#pragma mark - Delegate

- (void)timeUpdated;
{
	[self updateClock];
}

- (void)slideUpdated;
{
	[self updateSlide];
}

- (void)pictureUpdated;
{
	[self updateFlickrImage];
}





#pragma mark - Text sizing


- (float)portWidth
{
	return announcementsWindow.frame.size.width;
}

- (float)portHeight
{
	return announcementsWindow.frame.size.height;
}



- (float)textScaleRatio;
{
	return [self portWidth] / 1024;
}

- (float)actualFontSizeForText:(NSString *)text withFont:(NSFont *)aFont withOriginalSize:(float)originalSize;
{
	float scaledSize = originalSize * [self textScaleRatio];
	
	aFont = [NSFont fontWithName:aFont.fontName size:scaledSize];
	
	float longestLineWidth = 1;
	
	NSArray * textComponents = [text componentsSeparatedByString:@"\n"];
	
	if ([textComponents count] < 2 || [text length] < 2)
	{
		NSDictionary * attribs = [NSDictionary dictionaryWithObject:aFont forKey:NSFontAttributeName];
		
		NSSize textSize = [text sizeWithAttributes:attribs];
		if (textSize.width > longestLineWidth)
			longestLineWidth = textSize.width;
	}
	else
	{
		for (NSString * line in textComponents)
		{
			NSDictionary * attribs = [NSDictionary dictionaryWithObject:aFont forKey:NSFontAttributeName];
			
			NSSize textSize = [line sizeWithAttributes:attribs];
			if (textSize.width > longestLineWidth)
				longestLineWidth = textSize.width;
		}
	}
	
	//NSLog(@"text width: %f, scaled text size: %f, original text size: %f", longestLineWidth, scaledSize, originalSize);
	
	if (longestLineWidth > [self portWidth] - ([self portWidth] * 0.1))
	{
		float ratio = ([self portWidth] - ([self portWidth] * 0.1)) / longestLineWidth;
		scaledSize = scaledSize * ratio;
	}
	
	//NSLog(@"final text size to fit: %f", scaledSize);
	
	return scaledSize;
}




#pragma mark - Control methods

- (IBAction)startSlideshow:(id)sender;
{
	if (announcementsWindow)
	{
		NSLog(@"show already running.");
		return;
	}

	NSLog(@"found %lu announcements to show.", [[announcerController currentAnnouncements] count]);

	//NSRect frameRect = NSMakeRect(100, 100, 340, 280);
	NSRect frameRect = [[NSScreen mainScreen] frame];

	announcementsWindow = [[PCOControlResponseWindow alloc] initWithContentRect:frameRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO screen:[NSScreen mainScreen]];
	announcementsWindow.keyPressDelegate = self;
	announcementsWindow.delegate = self;
	[announcementsWindow setLevel:NSScreenSaverWindowLevel];
	[announcementsWindow setBackgroundColor:[NSColor blackColor]];

	[announcementsWindow makeKeyAndOrderFront:self];

	[NSCursor setHiddenUntilMouseMoves:YES];

	[[announcementsWindow contentView] setWantsLayer:YES];
	
	
	//if ([announcerController shouldShowClock] == YES)
	//{
		clockLayer = [CATextLayer layer];
		
		clockLayer.frame = [[[announcementsWindow contentView] layer] bounds];
		
		clockLayer.string = [announcerController currentClockString];
		
		float clockSize = 35;
		NSFont * clockFont = [NSFont fontWithName:@"Myriad Pro Bold" size:clockSize];
		clockSize = [self actualFontSizeForText:clockLayer.string withFont:clockFont withOriginalSize:clockSize];
		clockFont = [NSFont fontWithName:clockFont.fontName size:clockSize];
		
		NSSize clockBoxSize = [clockLayer.string sizeWithAttributes:[NSDictionary dictionaryWithObject:clockFont forKey:NSFontAttributeName]];
		
		clockLayer.foregroundColor = CGColorCreateGenericRGB(1, 1, 1, 1.0);
		clockLayer.font = (__bridge CFTypeRef)clockFont;
		clockLayer.fontSize = clockSize;
		clockLayer.alignmentMode = kCAAlignmentCenter;
		clockLayer.shadowOpacity = 1.0;
		
		clockLayer.frame = CGRectMake(20, 20, [[[announcementsWindow contentView] layer] bounds].size.width - 40, clockBoxSize.height);
		
		[[[announcementsWindow contentView] layer] addSublayer:clockLayer];


		bigClockLayer = [CATextLayer layer];

		bigClockLayer.frame = [[[announcementsWindow contentView] layer] bounds];

		bigClockLayer.string = @"0:00";

		float bigClockSize = 150;
		NSFont * bigClockFont = [NSFont fontWithName:@"Myriad Pro Bold" size:bigClockSize];
		bigClockSize = [self actualFontSizeForText:bigClockLayer.string withFont:bigClockFont withOriginalSize:bigClockSize];
		bigClockFont = [NSFont fontWithName:bigClockFont.fontName size:bigClockSize];

		NSSize bigClockBoxSize = [bigClockLayer.string sizeWithAttributes:[NSDictionary dictionaryWithObject:bigClockFont forKey:NSFontAttributeName]];

		bigClockLayer.foregroundColor = CGColorCreateGenericRGB(1, 1, 1, 1.0);
		bigClockLayer.font = (__bridge CFTypeRef)bigClockFont;
		bigClockLayer.fontSize = bigClockSize;
		bigClockLayer.alignmentMode = kCAAlignmentCenter;
		bigClockLayer.shadowOpacity = 1.0;

		bigClockLayer.frame = CGRectMake(20, ([[[announcementsWindow contentView] layer] bounds].size.height / 2) - (bigClockBoxSize.height / 2), [[[announcementsWindow contentView] layer] bounds].size.width - 40, bigClockBoxSize.height);

		[[[announcementsWindow contentView] layer] addSublayer:bigClockLayer];

		bigClockLayer.hidden = YES;
		
	//}
	
	if ([announcerController shouldShowFlickr] == YES && [[NSScreen screens] count] > 1)
	{
		flickrWindow = [[PCOControlResponseWindow alloc] initWithContentRect:[[[NSScreen screens] objectAtIndex:1] frame] styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
		flickrWindow.keyPressDelegate = self;
		flickrWindow.delegate = self;
		[flickrWindow setLevel:NSScreenSaverWindowLevel];
		[flickrWindow setBackgroundColor:[NSColor blackColor]];
		
		[flickrWindow makeKeyAndOrderFront:self];
		
		[[flickrWindow contentView] setWantsLayer:YES];
		
		[self nextPicture];
	}
	
	
	
	if ([[announcerController announcements] count] > 0)
	{
		[self nextSlide];
	}
	else
	{
		[self showBigLogo];
	}
}

- (void)updateClock;
{
	if ([announcerController shouldShowBigCountdown])
	{
		titleLayer.hidden = YES;
		bodyLayer.hidden = YES;
		backgroundLayer.hidden = YES;
		clockLayer.hidden = YES;

		bigClockLayer.hidden = NO;
	}
	else
	{
		titleLayer.hidden = NO;
		bodyLayer.hidden = NO;
		backgroundLayer.hidden = NO;
		clockLayer.hidden = NO;

		bigClockLayer.hidden = YES;
	}

	bigClockLayer.string = [announcerController currentClockString];
	clockLayer.string = [announcerController currentClockString];
}


- (void)updateSlide;
{

	[titleLayer removeFromSuperlayer];
	titleLayer = nil;

	[bodyLayer removeFromSuperlayer];
	bodyLayer = nil;

	[backgroundLayer removeFromSuperlayer];

	[logoLayer removeFromSuperlayer];


	

	if (announcerController.currentBackgroundPath)
	{
		NSError * loadErr = nil;

		QTMovie * backgroundMovie = [QTMovie movieWithFile:announcerController.currentBackgroundPath error:&loadErr];
		backgroundLayer = [QTMovieLayer layerWithMovie:backgroundMovie];
		backgroundLayer.contentsGravity = kCAGravityResizeAspect;

		if (loadErr)
		{
			NSLog(@"err: %@", [loadErr localizedDescription]);
		}

		backgroundLayer.frame = [[announcementsWindow contentView] layer].bounds;

		[[[announcementsWindow contentView] layer] insertSublayer:backgroundLayer below:clockLayer];
	}
	


	float titleFontSize = [self actualFontSizeForText:announcerController.currentTitle withFont:[NSFont fontWithName:@"Myriad Pro Bold" size:55] withOriginalSize:55];
	NSFont * titleFont = [NSFont fontWithName:@"Myriad Pro Bold" size:titleFontSize];

	NSSize titleBoxSize = [announcerController.currentTitle sizeWithAttributes:[NSDictionary dictionaryWithObject:titleFont forKey:NSFontAttributeName]];

	titleLayer = [CATextLayer layer];
	titleLayer.frame = CGRectMake(backgroundLayer.bounds.origin.x, backgroundLayer.bounds.size.height - titleBoxSize.height - 10, backgroundLayer.bounds.size.width, titleBoxSize.height);
	titleLayer.string = announcerController.currentTitle;
	titleLayer.foregroundColor = CGColorCreateGenericRGB(1, 1, 1, 1.0);
	titleLayer.font = (__bridge CFTypeRef)titleFont;
	titleLayer.fontSize = titleFontSize;
	titleLayer.alignmentMode = kCAAlignmentCenter;
	[backgroundLayer addSublayer:titleLayer];


	float bodyFontSize = [self actualFontSizeForText:announcerController.currentBody withFont:[NSFont fontWithName:@"Myriad Pro" size:45] withOriginalSize:45];
	NSFont * bodyFont = [NSFont fontWithName:@"Myriad Pro" size:bodyFontSize];

	bodyLayer = [CATextLayer layer];
	bodyLayer.frame = CGRectMake(backgroundLayer.bounds.origin.x, backgroundLayer.bounds.origin.y, backgroundLayer.bounds.size.width, backgroundLayer.bounds.size.height - titleBoxSize.height - 45);
	bodyLayer.string = announcerController.currentBody;
	bodyLayer.foregroundColor = CGColorCreateGenericRGB(1, 1, 1, 1);
	bodyLayer.font = (__bridge CFTypeRef)bodyFont;
	bodyLayer.fontSize = bodyFontSize;
	bodyLayer.alignmentMode = kCAAlignmentCenter;
	[backgroundLayer addSublayer:bodyLayer];

	[NSCursor setHiddenUntilMouseMoves:YES];


	if (announcerController.showLogo)
	{
		if (announcerController.logoUrl)
		{
			[announcerController loadLogoWithCompletionBlock:^{

				NSError * loadErr = nil;

				QTMovie * logoMovie = [QTMovie movieWithFile:announcerController.logoPath error:&loadErr];
				logoLayer = [QTMovieLayer layerWithMovie:logoMovie];
				logoLayer.contentsGravity = kCAGravityResizeAspectFill;
				
				if (loadErr)
				{
					NSLog(@"logo err: %@", [loadErr localizedDescription]);
				}

				logoLayer.frame = CGRectMake(backgroundLayer.frame.size.width - 350, 0, 300, 200);
				
				[backgroundLayer addSublayer:logoLayer];
				

			} andErrorBlock:^(NSError * error) {

				

			}];
		}
	}

}

- (void)updateFlickrImage;
{
	[flickrLayer removeFromSuperlayer];
	flickrLayer = nil;

	QTMovie * backgroundMovie = [QTMovie movieWithFile:announcerController.currentFlickrImagePath error:nil];
	flickrLayer = [QTMovieLayer layerWithMovie:backgroundMovie];
	flickrLayer.contentsGravity = kCAGravityResizeAspect;

	flickrLayer.frame = [[flickrWindow contentView] layer].bounds;

	[[[flickrWindow contentView] layer] addSublayer:flickrLayer];
}



- (void)showBigLogo;
{
	
	[titleLayer removeFromSuperlayer];
	titleLayer = nil;

	[bodyLayer removeFromSuperlayer];
	bodyLayer = nil;

	[backgroundLayer removeFromSuperlayer];

	[logoLayer removeFromSuperlayer];
	logoLayer = nil;


	[announcerController showBigLogoWithCompletion:^{

		NSError * loadErr = nil;

		NSString * backgroundPath = announcerController.logoPath;

		QTMovie * backgroundMovie = [QTMovie movieWithFile:backgroundPath error:&loadErr];
		backgroundLayer = [QTMovieLayer layerWithMovie:backgroundMovie];
		backgroundLayer.contentsGravity = kCAGravityResizeAspect;
		
		if (loadErr)
		{
			NSLog(@"err: %@", [loadErr localizedDescription]);
		}

		backgroundLayer.frame = [[announcementsWindow contentView] layer].bounds;

		[[[announcementsWindow contentView] layer] insertSublayer:backgroundLayer below:clockLayer];

	}];
	
	
	[NSCursor setHiddenUntilMouseMoves:YES];

}






- (void)nextSlide;
{
	
	[announcerController showNextSlideWithCompletion:^{

		[self updateSlide];
		
	}];

}


- (void)nextPicture;
{
	NSLog(@"next flickr");
	
	
	[announcerController showNextFlickrImageWithCompletion:^{

		[self updateFlickrImage];

	}];
	
	
}




- (IBAction)endSlideshow:(id)sender
{
	[announcementsWindow orderOut:sender];
	announcementsWindow = nil;
	
	backgroundLayer = nil;
	titleLayer = nil;
	bodyLayer = nil;

	logoLayer = nil;
	
	
	
	[flickrLayer removeFromSuperlayer];
	
	[flickrWindow orderOut:sender];
	flickrWindow = nil;
	
	[announcerController allStop];
}




#pragma mark - Keyboard shortcuts

- (void)leftArrowPressed;
{
	
}

- (void)rightArrowPressed;
{
	[self nextSlide];
	[self nextPicture];
}

- (void)upArrowPressed;
{
	
}

- (void)downArrowPressed;
{
	[self nextSlide];
	[self nextPicture];
}

- (void)spaceBarPressed;
{
	[self nextSlide];
	[self nextPicture];
}

- (void)returnKeyPressed;
{
	
}

- (void)escapeKeyPressed;
{
	[self endSlideshow:self];
}

@end
