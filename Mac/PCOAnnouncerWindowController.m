//
//  PCOAnnouncerWindowController.m
//  Announcer
//
//  Created by Jason Terhorst on 5/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PCOAnnouncerWindowController.h"

#import "CAAnimationBlockDelegate.h"

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

		//[self nextSlide];
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
	
	[announcerController loadFeedAndUpdateImagesWithCompletionBlock:^{

		[announcementsActivitySpinner stopAnimation:sender];

		announcementsStatusLabel.stringValue = [NSString stringWithFormat:@"Feed is ready. Found %ld announcements", [announcerController.announcements count]];

		if (announcementsWindow)
		{
			[self nextSlide];
		}

	} errorBlock:^(NSError * error) {

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

	if (!aFont)
	{
		aFont = [NSFont systemFontOfSize:scaledSize];
	}
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
	
	[announcementsActivitySpinner startAnimation:nil];

	if ([[announcerController announcements] count] > 0)
	{
		[self _setupOutput];
	}
	else
	{
		[announcerController loadFeedAndUpdateImagesWithCompletionBlock:^{

			[self _setupOutput];

		} errorBlock:^(NSError * error) {

			[announcementsActivitySpinner stopAnimation:nil];

			NSAlert * errAlert = [NSAlert alertWithError:error];
			[errAlert runModal];
			
		}];
	}

}

- (void)_setupOutput;
{
	[announcerController loadFlickrFeedWithCompletionBlock:^{

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

	} andErrorBlock:^(NSError * error) {

	}];

	[announcementsActivitySpinner stopAnimation:nil];

	NSLog(@"found %lu announcements to show.", [[announcerController currentAnnouncements] count]);

#if defined DEBUG
	NSRect frameRect = NSMakeRect(100, 100, 340, 280);
#else
	NSRect frameRect = [[NSScreen mainScreen] frame];
#endif

	announcementsWindow = [[PCOControlResponseWindow alloc] initWithContentRect:frameRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO screen:[NSScreen mainScreen]];
	announcementsWindow.keyPressDelegate = self;
	announcementsWindow.delegate = self;
	[announcementsWindow setLevel:NSScreenSaverWindowLevel];
	[announcementsWindow setBackgroundColor:[NSColor blackColor]];

	[announcementsWindow makeKeyAndOrderFront:self];

	[NSCursor setHiddenUntilMouseMoves:YES];

	[[announcementsWindow contentView] setWantsLayer:YES];


	clockLayer = [CATextLayer layer];

	clockLayer.frame = [[[announcementsWindow contentView] layer] bounds];

	clockLayer.string = [announcerController currentClockString];

	float clockSize = 35;
	NSFont * clockFont = [NSFont fontWithName:@"Myriad Pro Bold" size:clockSize];
	if (!clockFont)
	{
		clockFont = [NSFont boldSystemFontOfSize:clockSize];
	}

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
	if (!bigClockFont)
	{
		bigClockFont = [NSFont boldSystemFontOfSize:bigClockSize];
	}

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

		activeBackgroundLayer.hidden = YES;
		backgroundLayer1.hidden = YES;
		backgroundLayer2.hidden = YES;

		[backgroundLayer1 removeFromSuperlayer];
		[backgroundLayer2 removeFromSuperlayer];
		[activeBackgroundLayer removeFromSuperlayer];
		backgroundLayer1 = nil;
		backgroundLayer2 = nil;
		activeBackgroundLayer = nil;

		clockLayer.hidden = YES;

		bigClockLayer.hidden = NO;
	}
	else if (![announcerController shouldShowBigCountdown] && !activeBackgroundLayer)
	{
		[self nextSlide];
	}
	else
	{
		titleLayer.hidden = NO;
		bodyLayer.hidden = NO;
		activeBackgroundLayer.hidden = NO;
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

	[logoLayer removeFromSuperlayer];

	__block CALayer * layerToFadeOut = activeBackgroundLayer;
	__block CALayer * layerToFadeIn = nil;

	
	if (announcerController.currentBackgroundPath && ![announcerController shouldShowBigCountdown])
	{
		NSError * loadErr = nil;

		QTMovie * backgroundMovie = [QTMovie movieWithFile:announcerController.currentBackgroundPath error:&loadErr];

		QTMovieLayer * newBackgroundLayer = [QTMovieLayer layerWithMovie:backgroundMovie];
		newBackgroundLayer.contentsGravity = kCAGravityResizeAspect;

		if (loadErr)
		{
			NSLog(@"err: %@", [loadErr localizedDescription]);
		}

		newBackgroundLayer.frame = [[announcementsWindow contentView] layer].bounds;

		[[[announcementsWindow contentView] layer] insertSublayer:newBackgroundLayer below:clockLayer];

		layerToFadeOut = activeBackgroundLayer;

		if (activeBackgroundLayer == backgroundLayer1)
		{
			backgroundLayer2 = newBackgroundLayer;
		}
		else if (activeBackgroundLayer == backgroundLayer2)
		{
			backgroundLayer1 = newBackgroundLayer;
		}

		layerToFadeIn = newBackgroundLayer;
		activeBackgroundLayer = newBackgroundLayer;

		CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
		animation.duration = 0.5;
		animation.repeatCount = 0;
		animation.fromValue = [NSNumber numberWithFloat:0];
		animation.toValue = [NSNumber numberWithFloat:1.0];

		CAAnimationBlockDelegate *delegate =
		[[CAAnimationBlockDelegate alloc] init];
		// Define block that gets invoked after
		// animation starts
		delegate.blockOnAnimationStarted = ^() {

		};
		// Define block that gets invoked after
		// animation succeeds
		delegate.blockOnAnimationSucceeded = ^() {

			CABasicAnimation * fadeOutAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
			fadeOutAnimation.duration = 0.5;
			fadeOutAnimation.repeatCount = 0;
			fadeOutAnimation.fromValue = [NSNumber numberWithFloat:1.0];
			fadeOutAnimation.toValue = [NSNumber numberWithFloat:0];

			CAAnimationBlockDelegate *delegate =
			[[CAAnimationBlockDelegate alloc] init];
			// Define block that gets invoked after
			// animation starts
			delegate.blockOnAnimationStarted = ^() {
				layerToFadeOut.opacity = 0;
			};
			// Define block that gets invoked after
			// animation succeeds
			delegate.blockOnAnimationSucceeded = ^() {
				if (layerToFadeOut == backgroundLayer1)
				{
					backgroundLayer1 = nil;
				}
				else if (layerToFadeOut == backgroundLayer2)
				{
					backgroundLayer2 = nil;
				}

				[layerToFadeOut removeFromSuperlayer];
				layerToFadeOut = nil;
			};
			fadeOutAnimation.delegate = delegate;

			[layerToFadeOut addAnimation:fadeOutAnimation forKey:@"fadeOut"];

		};
		animation.delegate = delegate;

		[layerToFadeIn addAnimation:animation forKey:@"fadeOut"];
	}
	else
	{
		CABasicAnimation * fadeOutAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
		fadeOutAnimation.duration = 0.5;
		fadeOutAnimation.repeatCount = 0;
		fadeOutAnimation.fromValue = [NSNumber numberWithFloat:1.0];
		fadeOutAnimation.toValue = [NSNumber numberWithFloat:0];

		CAAnimationBlockDelegate *delegate =
		[[CAAnimationBlockDelegate alloc] init];
		// Define block that gets invoked after
		// animation starts
		delegate.blockOnAnimationStarted = ^() {
			// your logic goes here ...
		};
		// Define block that gets invoked after
		// animation succeeds
		delegate.blockOnAnimationSucceeded = ^() {
			if (layerToFadeOut == backgroundLayer1)
			{
				backgroundLayer1 = nil;
			}
			else if (layerToFadeOut == backgroundLayer2)
			{
				backgroundLayer2 = nil;
			}

			[layerToFadeOut removeFromSuperlayer];
			layerToFadeOut = nil;

			[backgroundLayer1 removeFromSuperlayer];
			[backgroundLayer2 removeFromSuperlayer];
			backgroundLayer1 = nil;
			backgroundLayer2 = nil;

			[activeBackgroundLayer removeFromSuperlayer];
			activeBackgroundLayer = nil;
		};
		fadeOutAnimation.delegate = delegate;

		[layerToFadeOut addAnimation:fadeOutAnimation forKey:@"fadeOut"];
	}



	NSFont * titleFont = [NSFont fontWithName:@"Myriad Pro Bold" size:55];
	if (!titleFont)
	{
		titleFont = [NSFont boldSystemFontOfSize:55];
	}

	float titleFontSize = [self actualFontSizeForText:announcerController.currentTitle withFont:titleFont withOriginalSize:55];
	titleFont = [NSFont fontWithName:titleFont.fontName size:titleFontSize];

	NSSize titleBoxSize = [announcerController.currentTitle sizeWithAttributes:[NSDictionary dictionaryWithObject:titleFont forKey:NSFontAttributeName]];

	titleLayer = [CATextLayer layer];
	titleLayer.frame = CGRectMake(activeBackgroundLayer.bounds.origin.x, activeBackgroundLayer.bounds.size.height - titleBoxSize.height - 10, activeBackgroundLayer.bounds.size.width, titleBoxSize.height);
	titleLayer.string = announcerController.currentTitle;
	titleLayer.foregroundColor = CGColorCreateGenericRGB(1, 1, 1, 1.0);
	titleLayer.font = (__bridge CFTypeRef)titleFont;
	titleLayer.fontSize = titleFontSize;
	titleLayer.alignmentMode = kCAAlignmentCenter;
	[activeBackgroundLayer addSublayer:titleLayer];


	NSFont * bodyFont = [NSFont fontWithName:@"Myriad Pro" size:45];
	if (!bodyFont)
	{
		bodyFont = [NSFont systemFontOfSize:45];
	}

	float bodyFontSize = [self actualFontSizeForText:announcerController.currentBody withFont:bodyFont withOriginalSize:45];

	bodyFont = [NSFont fontWithName:bodyFont.fontName size:bodyFont.pointSize];


	bodyLayer = [CATextLayer layer];
	bodyLayer.frame = CGRectMake(activeBackgroundLayer.bounds.origin.x, activeBackgroundLayer.bounds.origin.y, activeBackgroundLayer.bounds.size.width, activeBackgroundLayer.bounds.size.height - titleBoxSize.height - 45);
	bodyLayer.string = announcerController.currentBody;
	bodyLayer.foregroundColor = CGColorCreateGenericRGB(1, 1, 1, 1);
	bodyLayer.font = (__bridge CFTypeRef)bodyFont;
	bodyLayer.fontSize = bodyFontSize;
	bodyLayer.alignmentMode = kCAAlignmentCenter;
	[activeBackgroundLayer addSublayer:bodyLayer];

	[NSCursor setHiddenUntilMouseMoves:YES];


	if (announcerController.showLogo)
	{
		if (announcerController.logoUrl)
		{
			[announcerController loadLogoWithCompletionBlock:^{

				/*
				NSError * loadErr = nil;

				QTMovie * logoMovie = [QTMovie movieWithFile:announcerController.logoPath error:&loadErr];
				logoLayer = [QTMovieLayer layerWithMovie:logoMovie];
				logoLayer.contentsGravity = kCAGravityResizeAspectFill;
				
				if (loadErr)
				{
					NSLog(@"logo err: %@", [loadErr localizedDescription]);
				}

				logoLayer.frame = CGRectMake(activeBackgroundLayer.frame.size.width - 350, 0, 300, 200);
				
				[activeBackgroundLayer addSublayer:logoLayer];
				*/

			} andErrorBlock:^(NSError * error) {

				

			}];
		}
	}

}


- (void)updateFlickrImage;
{
	if (!flickrWindow)
	{
		return;
	}

	__block CALayer * layerToFadeOut = activeFlickrLayer;
	__block CALayer * layerToFadeIn = nil;
	
	
	NSError * loadErr = nil;

	if (![[NSFileManager defaultManager] fileExistsAtPath:announcerController.currentFlickrImagePath])
	{
		NSLog(@"flickr file doesn't exist");
	}

	QTMovie * backgroundMovie = [QTMovie movieWithFile:announcerController.currentFlickrImagePath error:&loadErr];

	if (loadErr)
	{
		NSLog(@"loading flickr error: %@", [loadErr localizedDescription]);
	}

	QTMovieLayer * newFlickrLayer = [QTMovieLayer layerWithMovie:backgroundMovie];
	newFlickrLayer.contentsGravity = kCAGravityResizeAspect;

	newFlickrLayer.frame = [[flickrWindow contentView] layer].bounds;

	[[[flickrWindow contentView] layer] addSublayer:newFlickrLayer];

	NSLog(@"showing flickr image....");

	layerToFadeOut = activeFlickrLayer;

	if (activeFlickrLayer == flickrLayer1)
	{
		flickrLayer2 = newFlickrLayer;
	}
	else if (activeFlickrLayer == flickrLayer2)
	{
		flickrLayer1 = newFlickrLayer;
	}

	layerToFadeIn = newFlickrLayer;
	activeFlickrLayer = newFlickrLayer;

	CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
	animation.duration = 0.5;
	animation.repeatCount = 0;
	animation.fromValue = [NSNumber numberWithFloat:0];
	animation.toValue = [NSNumber numberWithFloat:1.0];

	CAAnimationBlockDelegate *delegate =
	[[CAAnimationBlockDelegate alloc] init];
	// Define block that gets invoked after
	// animation starts
	delegate.blockOnAnimationStarted = ^() {

	};
	// Define block that gets invoked after
	// animation succeeds
	delegate.blockOnAnimationSucceeded = ^() {

		CABasicAnimation * fadeOutAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
		fadeOutAnimation.duration = 0.5;
		fadeOutAnimation.repeatCount = 0;
		fadeOutAnimation.fromValue = [NSNumber numberWithFloat:1.0];
		fadeOutAnimation.toValue = [NSNumber numberWithFloat:0];

		CAAnimationBlockDelegate *delegate =
		[[CAAnimationBlockDelegate alloc] init];
		// Define block that gets invoked after
		// animation starts
		delegate.blockOnAnimationStarted = ^() {
			// your logic goes here ...
		};
		// Define block that gets invoked after
		// animation succeeds
		delegate.blockOnAnimationSucceeded = ^() {
			if (layerToFadeOut == flickrLayer1)
			{
				flickrLayer1 = nil;
			}
			else if (layerToFadeOut == flickrLayer2)
			{
				flickrLayer2 = nil;
			}

			[layerToFadeOut removeFromSuperlayer];
			layerToFadeOut = nil;

		};
		fadeOutAnimation.delegate = delegate;
		
		[layerToFadeOut addAnimation:fadeOutAnimation forKey:@"fadeOut"];

		NSLog(@"flickr image faded in");

	};
	animation.delegate = delegate;

	[layerToFadeIn addAnimation:animation forKey:@"fadeOut"];

	NSLog(@"animations created");

}



- (void)showBigLogo;
{
	if ([[announcerController announcements] count] == 0)
	{
		return;
	}


	[titleLayer removeFromSuperlayer];
	titleLayer = nil;

	[bodyLayer removeFromSuperlayer];
	bodyLayer = nil;

	[activeBackgroundLayer removeFromSuperlayer];
	[backgroundLayer1 removeFromSuperlayer];
	[backgroundLayer2 removeFromSuperlayer];
	activeBackgroundLayer = nil;
	backgroundLayer1 = nil;
	backgroundLayer2 = nil;

	[logoLayer removeFromSuperlayer];
	logoLayer = nil;


	[announcerController showBigLogoWithCompletion:^{

		NSError * loadErr = nil;

		NSString * backgroundPath = announcerController.logoPath;

		QTMovie * backgroundMovie = [QTMovie movieWithFile:backgroundPath error:&loadErr];
		activeBackgroundLayer = [QTMovieLayer layerWithMovie:backgroundMovie];
		activeBackgroundLayer.contentsGravity = kCAGravityResizeAspect;
		
		if (loadErr)
		{
			NSLog(@"err: %@", [loadErr localizedDescription]);
		}

		activeBackgroundLayer.frame = [[announcementsWindow contentView] layer].bounds;

		[[[announcementsWindow contentView] layer] insertSublayer:activeBackgroundLayer below:clockLayer];

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

		NSLog(@"flickr model updated. displaying image.");
		[self updateFlickrImage];

	}];
	
	
}




- (IBAction)endSlideshow:(id)sender
{
	[announcementsWindow orderOut:sender];
	announcementsWindow = nil;
	
	activeBackgroundLayer = nil;
	backgroundLayer1 = nil;
	backgroundLayer2 = nil;

	titleLayer = nil;
	bodyLayer = nil;

	logoLayer = nil;
	
	
	
	[activeFlickrLayer removeFromSuperlayer];
	activeFlickrLayer = nil;
	[flickrLayer1 removeFromSuperlayer];
	flickrLayer1 = nil;
	[flickrLayer2 removeFromSuperlayer];
	flickrLayer2 = nil;
	
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
