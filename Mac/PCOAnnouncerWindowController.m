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
		[appDefaults setObject:@"1" forKey:@"churchId"];
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
	NSString * feedUrl = [NSString stringWithFormat:@"http://announcer.heroku.com/feeds/%@.json", announcementsFeedField.stringValue];
	NSLog(@"feed: %@", feedUrl);
	
	if (feedUrl == nil || [feedUrl length] == 0)
	{
		announcementsStatusLabel.stringValue = @"Please enter a valid feed URL";
		return;
	}
	
	[announcementsActivitySpinner startAnimation:sender];
	
	[announcerController loadAnnouncementsFromFeedLocation:feedUrl withCompletionBlock:^{
		
		[announcementsActivitySpinner stopAnimation:sender];
		
		announcementsStatusLabel.stringValue = [NSString stringWithFormat:@"Feed is ready. Found %ld announcements", [announcerController.announcements count]];
		
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
		
		flickrStatusLabel.stringValue = [NSString stringWithFormat:@"Feed is ready. Found %ld images", [announcerController.flickrImageUrls count]];
		
	} andErrorBlock:^(NSError * error) {
		NSLog(@"error: %@", [error localizedDescription]);
		
		[flickrActivitySpinner stopAnimation:sender];
		
		flickrStatusLabel.stringValue = @"Failed trying to update Flickr feed";
		
	}];
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






- (IBAction)startSlideshow:(id)sender;
{
	if (announcementsWindow)
	{
		NSLog(@"show already running.");
		return;
	}
	
	NSLog(@"found %lu announcements to show.", [[announcerController currentAnnouncements] count]);
	
	NSRect frameRect = NSMakeRect(100, 100, 340, 280);
	//NSRect frameRect = [[NSScreen mainScreen] frame];
	
	announcementsWindow = [[PCOControlResponseWindow alloc] initWithContentRect:frameRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO screen:[NSScreen mainScreen]];
	announcementsWindow.keyPressDelegate = self;
	announcementsWindow.delegate = self;
	[announcementsWindow setLevel:NSScreenSaverWindowLevel];
	[announcementsWindow setBackgroundColor:[NSColor blackColor]];
	
	[announcementsWindow makeKeyAndOrderFront:self];
	
	[NSCursor setHiddenUntilMouseMoves:YES];
	
	[[announcementsWindow contentView] setWantsLayer:YES];
	
	
	
	if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"show_clock"] boolValue] == YES)
	{
		clockLayer = [CATextLayer layer];
		NSDateFormatter *df = [[NSDateFormatter alloc] init];
		//[df setDateFormat:@"yyyy/MM/dd hh:mm:ss Z"];
		[df setDateStyle:NSDateFormatterLongStyle];
		[df setTimeStyle:NSDateFormatterLongStyle];
		
		clockLayer.frame = [[[announcementsWindow contentView] layer] bounds];
		
		clockLayer.string = [df stringFromDate:[NSDate date]];
		
		float clockSize = 35;
		NSFont * clockFont = [NSFont fontWithName:@"Myriad Pro Bold" size:clockSize];
		clockSize = [self actualFontSizeForText:clockLayer.string withFont:clockFont withOriginalSize:clockSize];
		clockFont = [NSFont fontWithName:clockFont.fontName size:clockSize];
		
		NSSize clockBoxSize = [clockLayer.string sizeWithAttributes:[NSDictionary dictionaryWithObject:clockFont forKey:NSFontAttributeName]];
		
		clockLayer.foregroundColor = CGColorCreateGenericRGB(1, 1, 1, 1.0);
		clockLayer.font = (__bridge CFTypeRef)clockFont;
		clockLayer.fontSize = clockSize;
		clockLayer.alignmentMode = kCAAlignmentRight;
		clockLayer.shadowOpacity = 1.0;
		
		clockLayer.frame = CGRectMake(20, 20, [[[announcementsWindow contentView] layer] bounds].size.width - 40, clockBoxSize.height);
		
		[[[announcementsWindow contentView] layer] addSublayer:clockLayer];
		
		clockTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateClock) userInfo:nil repeats:YES];
	}
	
	if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"show_flickr"] boolValue] == YES && [[NSScreen screens] count] > 1)
	{
		currentFlickrIndex = -1;
		
		flickrWindow = [[PCOControlResponseWindow alloc] initWithContentRect:[[[NSScreen screens] objectAtIndex:1] frame] styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
		flickrWindow.keyPressDelegate = self;
		flickrWindow.delegate = self;
		[flickrWindow setLevel:NSScreenSaverWindowLevel];
		[flickrWindow setBackgroundColor:[NSColor blackColor]];
		
		[flickrWindow makeKeyAndOrderFront:self];
		
		[[flickrWindow contentView] setWantsLayer:YES];
		
		
		float secondsPerPicture = 10;
		if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"seconds_per_picture"] floatValue] > 0)
		{
			secondsPerPicture = [[[NSUserDefaults standardUserDefaults] valueForKey:@"seconds_per_picture"] floatValue];
		}
		
		[self nextPicture];
		
		flickrTimer = [NSTimer scheduledTimerWithTimeInterval:secondsPerPicture target:self selector:@selector(nextPicture) userInfo:nil repeats:YES];
	}
	
	
	currentSlideIndex = -1;
	
	[self nextSlide];
}

- (void)updateClock;
{
	NSDateFormatter *df = [[NSDateFormatter alloc] init];
	//[df setDateFormat:@"yyyy/MM/dd hh:mm:ss Z"];
	[df setDateStyle:NSDateFormatterLongStyle];
	[df setTimeStyle:NSDateFormatterLongStyle];
	
	NSLog(@"time: %@", [df stringFromDate:[NSDate date]]);
	
	clockLayer.string = [df stringFromDate:[NSDate date]];
}

- (void)showBigLogo;
{

	NSInteger slideIndex = -1;
	

	[slideTimer invalidate], slideTimer = nil;

	NSLog(@"playing slide %ld", slideIndex);




	[titleLayer removeFromSuperlayer];
	titleLayer = nil;

	[bodyLayer removeFromSuperlayer];
	bodyLayer = nil;

	[backgroundLayer removeFromSuperlayer];


	NSString * backgroundUrl = announcerController.logoUrl;
	NSString * backgroundPath = nil;
	if ([backgroundUrl isKindOfClass:[NSString class]])
	{
		backgroundPath = [announcerController pathForImageFileAtUrl:backgroundUrl];
	}

	if (backgroundPath)
	{
		NSError * loadErr = nil;

		if (![[NSFileManager defaultManager] fileExistsAtPath:backgroundPath])
		{
			NSLog(@"media resource missing from path: %@", backgroundPath);

			[announcerController downloadImageFromUrl:backgroundUrl withCompletionBlock:^{

				QTMovie * backgroundMovie = [QTMovie movieWithFile:backgroundPath error:nil];
				backgroundLayer = [QTMovieLayer layerWithMovie:backgroundMovie];
				backgroundLayer.contentsGravity = kCAGravityResizeAspect;

				if (loadErr)
				{
					NSLog(@"err: %@", [loadErr localizedDescription]);
				}

				backgroundLayer.frame = [[announcementsWindow contentView] layer].bounds;

				[[[announcementsWindow contentView] layer] insertSublayer:backgroundLayer below:clockLayer];

				

			} andErrorBlock:^(NSError * err) {

				backgroundLayer = [QTMovieLayer layer];

				backgroundLayer.frame = [[announcementsWindow contentView] layer].bounds;

				[[[announcementsWindow contentView] layer] insertSublayer:backgroundLayer below:clockLayer];



			}];
		}
		else // if image exists
		{
			QTMovie * backgroundMovie = [QTMovie movieWithFile:backgroundPath error:&loadErr];
			backgroundLayer = [QTMovieLayer layerWithMovie:backgroundMovie];
			backgroundLayer.contentsGravity = kCAGravityResizeAspect;

			if (loadErr)
			{
				NSLog(@"err: %@", [loadErr localizedDescription]);
			}

			backgroundLayer.frame = [[announcementsWindow contentView] layer].bounds;

			[[[announcementsWindow contentView] layer] insertSublayer:backgroundLayer below:clockLayer];


		}

	}
	else
	{
		backgroundLayer = [QTMovieLayer layer];

		backgroundLayer.frame = [[announcementsWindow contentView] layer].bounds;

		[[[announcementsWindow contentView] layer] insertSublayer:backgroundLayer below:clockLayer];


	}



	[NSCursor setHiddenUntilMouseMoves:YES];

}

- (void)nextSlide;
{
	if ([[announcerController currentAnnouncements] count] == 0)
	{
		// just show logo
		[self showBigLogo];

		return;
	}

	
	NSInteger slideIndex = currentSlideIndex + 1;
	
	if (slideIndex < 0)
	{
		slideIndex = 0;
	}
	
	if (slideIndex >= [[announcerController currentAnnouncements] count])
	{
		slideIndex = 0;
	}
	
	[slideTimer invalidate], slideTimer = nil;
	
	float slideDuration = 10;
	
	NSLog(@"playing slide %ld", slideIndex);
	
	NSString * titleText = nil;//[[[announcerController currentAnnouncements] objectAtIndex:slideIndex] objectForKey:@"title"];
	if (![[[[announcerController currentAnnouncements] objectAtIndex:slideIndex] objectForKey:@"title"] isEqual:[NSNull null]])
	{
		titleText = [[[announcerController currentAnnouncements] objectAtIndex:slideIndex] objectForKey:@"title"];
	}
	NSString * bodyText = nil;//[[[announcerController currentAnnouncements] objectAtIndex:slideIndex] objectForKey:@"body"];
	if (![[[[announcerController currentAnnouncements] objectAtIndex:slideIndex] objectForKey:@"body"] isEqual:[NSNull null]])
	{
		bodyText = [[[announcerController currentAnnouncements] objectAtIndex:slideIndex] objectForKey:@"body"];
	}
	
	
	if ([[[announcerController currentAnnouncements] objectAtIndex:slideIndex] objectForKey:@"duration_seconds"])
	{
		slideDuration = [[[[announcerController currentAnnouncements] objectAtIndex:slideIndex] objectForKey:@"duration_seconds"] floatValue];
	}
	
	
	[titleLayer removeFromSuperlayer];
	titleLayer = nil;
	
	[bodyLayer removeFromSuperlayer];
	bodyLayer = nil;
	
	[backgroundLayer removeFromSuperlayer];
	
	
	NSString * backgroundUrl = [[[announcerController currentAnnouncements] objectAtIndex:slideIndex] objectForKey:@"background_file_url"];
	NSString * backgroundPath = nil;
	if ([backgroundUrl isKindOfClass:[NSString class]])
	{
		backgroundPath = [announcerController pathForImageFileAtUrl:backgroundUrl];
	}
	
	if (backgroundPath)
	{
		NSError * loadErr = nil;
		
		if (![[NSFileManager defaultManager] fileExistsAtPath:backgroundPath])
		{
			NSLog(@"media resource missing from path: %@", backgroundPath);
			
			[announcerController downloadImageFromUrl:backgroundUrl withCompletionBlock:^{
				
				QTMovie * backgroundMovie = [QTMovie movieWithFile:backgroundPath error:nil];
				backgroundLayer = [QTMovieLayer layerWithMovie:backgroundMovie];
				backgroundLayer.contentsGravity = kCAGravityResizeAspect;
				
				if (loadErr)
				{
					NSLog(@"err: %@", [loadErr localizedDescription]);
				}
				
				backgroundLayer.frame = [[announcementsWindow contentView] layer].bounds;
				
				[[[announcementsWindow contentView] layer] insertSublayer:backgroundLayer below:clockLayer];
				
				
				float titleFontSize = [self actualFontSizeForText:titleText withFont:[NSFont fontWithName:@"Myriad Pro Bold" size:55] withOriginalSize:55];
				NSFont * titleFont = [NSFont fontWithName:@"Myriad Pro Bold" size:titleFontSize];
				
				NSSize titleBoxSize = [titleText sizeWithAttributes:[NSDictionary dictionaryWithObject:titleFont forKey:NSFontAttributeName]];
				
				titleLayer = [CATextLayer layer];
				titleLayer.frame = CGRectMake(backgroundLayer.bounds.origin.x, backgroundLayer.bounds.size.height - titleBoxSize.height - 10, backgroundLayer.bounds.size.width, titleBoxSize.height);
				titleLayer.string = titleText;
				titleLayer.foregroundColor = CGColorCreateGenericRGB(1, 1, 1, 1.0);
				titleLayer.font = (__bridge CFTypeRef)titleFont;
				titleLayer.fontSize = titleFontSize;
				titleLayer.alignmentMode = kCAAlignmentCenter;
				[backgroundLayer addSublayer:titleLayer];
				
				
				float bodyFontSize = [self actualFontSizeForText:bodyText withFont:[NSFont fontWithName:@"Myriad Pro" size:45] withOriginalSize:45];
				NSFont * bodyFont = [NSFont fontWithName:@"Myriad Pro" size:bodyFontSize];
				
				bodyLayer = [CATextLayer layer];
				bodyLayer.frame = CGRectMake(backgroundLayer.bounds.origin.x, backgroundLayer.bounds.origin.y, backgroundLayer.bounds.size.width, backgroundLayer.bounds.size.height - titleBoxSize.height - 45);
				bodyLayer.string = bodyText;
				bodyLayer.foregroundColor = CGColorCreateGenericRGB(1, 1, 1, 1);
				bodyLayer.font = (__bridge CFTypeRef)bodyFont;
				bodyLayer.fontSize = bodyFontSize;
				bodyLayer.alignmentMode = kCAAlignmentCenter;
				[backgroundLayer addSublayer:bodyLayer];
				
			} andErrorBlock:^(NSError * err) {
				
				backgroundLayer = [QTMovieLayer layer];
				
				backgroundLayer.frame = [[announcementsWindow contentView] layer].bounds;
				
				[[[announcementsWindow contentView] layer] insertSublayer:backgroundLayer below:clockLayer];
				
				
				float titleFontSize = [self actualFontSizeForText:titleText withFont:[NSFont fontWithName:@"Myriad Pro Bold" size:55] withOriginalSize:55];
				NSFont * titleFont = [NSFont fontWithName:@"Myriad Pro Bold" size:titleFontSize];
				
				NSSize titleBoxSize = [titleText sizeWithAttributes:[NSDictionary dictionaryWithObject:titleFont forKey:NSFontAttributeName]];
				
				titleLayer = [CATextLayer layer];
				titleLayer.frame = CGRectMake(backgroundLayer.bounds.origin.x, backgroundLayer.bounds.size.height - titleBoxSize.height - 10, backgroundLayer.bounds.size.width, titleBoxSize.height);
				titleLayer.string = titleText;
				titleLayer.foregroundColor = CGColorCreateGenericRGB(1, 1, 1, 1.0);
				titleLayer.font = (__bridge CFTypeRef)titleFont;
				titleLayer.fontSize = titleFontSize;
				titleLayer.alignmentMode = kCAAlignmentCenter;
				[backgroundLayer addSublayer:titleLayer];
				
				
				float bodyFontSize = [self actualFontSizeForText:bodyText withFont:[NSFont fontWithName:@"Myriad Pro" size:45] withOriginalSize:45];
				NSFont * bodyFont = [NSFont fontWithName:@"Myriad Pro" size:bodyFontSize];
				
				bodyLayer = [CATextLayer layer];
				bodyLayer.frame = CGRectMake(backgroundLayer.bounds.origin.x, backgroundLayer.bounds.origin.y, backgroundLayer.bounds.size.width, backgroundLayer.bounds.size.height - titleBoxSize.height - 45);
				bodyLayer.string = bodyText;
				bodyLayer.foregroundColor = CGColorCreateGenericRGB(1, 1, 1, 1);
				bodyLayer.font = (__bridge CFTypeRef)bodyFont;
				bodyLayer.fontSize = bodyFontSize;
				bodyLayer.alignmentMode = kCAAlignmentCenter;
				[backgroundLayer addSublayer:bodyLayer];
				
			}];
		}
		else // if image exists
		{
			QTMovie * backgroundMovie = [QTMovie movieWithFile:backgroundPath error:&loadErr];
			backgroundLayer = [QTMovieLayer layerWithMovie:backgroundMovie];
			backgroundLayer.contentsGravity = kCAGravityResizeAspect;
			
			if (loadErr)
			{
				NSLog(@"err: %@", [loadErr localizedDescription]);
			}
			
			backgroundLayer.frame = [[announcementsWindow contentView] layer].bounds;
			
			[[[announcementsWindow contentView] layer] insertSublayer:backgroundLayer below:clockLayer];
			
			
			float titleFontSize = [self actualFontSizeForText:titleText withFont:[NSFont fontWithName:@"Myriad Pro Bold" size:55] withOriginalSize:55];
			NSFont * titleFont = [NSFont fontWithName:@"Myriad Pro Bold" size:titleFontSize];
			
			NSSize titleBoxSize = [titleText sizeWithAttributes:[NSDictionary dictionaryWithObject:titleFont forKey:NSFontAttributeName]];
			
			titleLayer = [CATextLayer layer];
			titleLayer.frame = CGRectMake(backgroundLayer.bounds.origin.x, backgroundLayer.bounds.size.height - titleBoxSize.height - 10, backgroundLayer.bounds.size.width, titleBoxSize.height);
			titleLayer.string = titleText;
			titleLayer.foregroundColor = CGColorCreateGenericRGB(1, 1, 1, 1.0);
			titleLayer.font = (__bridge CFTypeRef)titleFont;
			titleLayer.fontSize = titleFontSize;
			titleLayer.alignmentMode = kCAAlignmentCenter;
			[backgroundLayer addSublayer:titleLayer];
			
			
			float bodyFontSize = [self actualFontSizeForText:bodyText withFont:[NSFont fontWithName:@"Myriad Pro" size:45] withOriginalSize:45];
			NSFont * bodyFont = [NSFont fontWithName:@"Myriad Pro" size:bodyFontSize];
			
			bodyLayer = [CATextLayer layer];
			bodyLayer.frame = CGRectMake(backgroundLayer.bounds.origin.x, backgroundLayer.bounds.origin.y, backgroundLayer.bounds.size.width, backgroundLayer.bounds.size.height - titleBoxSize.height - 45);
			bodyLayer.string = bodyText;
			bodyLayer.foregroundColor = CGColorCreateGenericRGB(1, 1, 1, 1);
			bodyLayer.font = (__bridge CFTypeRef)bodyFont;
			bodyLayer.fontSize = bodyFontSize;
			bodyLayer.alignmentMode = kCAAlignmentCenter;
			[backgroundLayer addSublayer:bodyLayer];
		}
		
	}
	else
	{
		backgroundLayer = [QTMovieLayer layer];
		
		backgroundLayer.frame = [[announcementsWindow contentView] layer].bounds;
		
		[[[announcementsWindow contentView] layer] insertSublayer:backgroundLayer below:clockLayer];
		
		
		float titleFontSize = [self actualFontSizeForText:titleText withFont:[NSFont fontWithName:@"Myriad Pro Bold" size:55] withOriginalSize:55];
		NSFont * titleFont = [NSFont fontWithName:@"Myriad Pro Bold" size:titleFontSize];
		
		NSSize titleBoxSize = [titleText sizeWithAttributes:[NSDictionary dictionaryWithObject:titleFont forKey:NSFontAttributeName]];
		
		titleLayer = [CATextLayer layer];
		titleLayer.frame = CGRectMake(backgroundLayer.bounds.origin.x, backgroundLayer.bounds.size.height - titleBoxSize.height - 10, backgroundLayer.bounds.size.width, titleBoxSize.height);
		titleLayer.string = titleText;
		titleLayer.foregroundColor = CGColorCreateGenericRGB(1, 1, 1, 1.0);
		titleLayer.font = (__bridge CFTypeRef)titleFont;
		titleLayer.fontSize = titleFontSize;
		titleLayer.alignmentMode = kCAAlignmentCenter;
		[backgroundLayer addSublayer:titleLayer];
		
		
		float bodyFontSize = [self actualFontSizeForText:bodyText withFont:[NSFont fontWithName:@"Myriad Pro" size:45] withOriginalSize:45];
		NSFont * bodyFont = [NSFont fontWithName:@"Myriad Pro" size:bodyFontSize];
		
		bodyLayer = [CATextLayer layer];
		bodyLayer.frame = CGRectMake(backgroundLayer.bounds.origin.x, backgroundLayer.bounds.origin.y, backgroundLayer.bounds.size.width, backgroundLayer.bounds.size.height - titleBoxSize.height - 45);
		bodyLayer.string = bodyText;
		bodyLayer.foregroundColor = CGColorCreateGenericRGB(1, 1, 1, 1);
		bodyLayer.font = (__bridge CFTypeRef)bodyFont;
		bodyLayer.fontSize = bodyFontSize;
		bodyLayer.alignmentMode = kCAAlignmentCenter;
		[backgroundLayer addSublayer:bodyLayer];
	}
	
	
	
	[NSCursor setHiddenUntilMouseMoves:YES];
	
	currentSlideIndex = slideIndex;
	
	slideTimer = [NSTimer scheduledTimerWithTimeInterval:slideDuration target:self selector:@selector(nextSlide) userInfo:nil repeats:NO];
}


- (void)nextPicture;
{
	NSLog(@"next flickr");
	
	[flickrLayer removeFromSuperlayer];
	flickrLayer = nil;
	
	NSInteger picIndex = currentFlickrIndex + 1;
	
	if (picIndex < 0)
	{
		picIndex = 0;
	}
	
	if (picIndex >= [[announcerController flickrImageUrls] count])
	{
		picIndex = 0;
	}
	
	
	NSString * backgroundUrl = [[announcerController flickrImageUrls] objectAtIndex:picIndex];
	NSString * backgroundPath = nil;
	if ([backgroundUrl isKindOfClass:[NSString class]])
	{
		backgroundPath = [announcerController pathForImageFileAtUrl:backgroundUrl];
	}
	
	if (backgroundPath)
	{
		NSError * loadErr = nil;
		
		if (![[NSFileManager defaultManager] fileExistsAtPath:backgroundPath])
		{
			NSLog(@"media resource missing from path: %@", backgroundPath);
			
			[announcerController downloadImageFromUrl:backgroundUrl withCompletionBlock:^{
				
				QTMovie * backgroundMovie = [QTMovie movieWithFile:backgroundPath error:nil];
				flickrLayer = [QTMovieLayer layerWithMovie:backgroundMovie];
				flickrLayer.contentsGravity = kCAGravityResizeAspect;
				
				flickrLayer.frame = [[flickrWindow contentView] layer].bounds;
				
				[[[flickrWindow contentView] layer] addSublayer:flickrLayer];
				
			} andErrorBlock:^(NSError * err) {
				
				flickrLayer = [QTMovieLayer layer];
				flickrLayer.frame = [[flickrWindow contentView] layer].bounds;
				
				[[[flickrWindow contentView] layer] addSublayer:flickrLayer];
				
			}];
		}
		else
		{
			QTMovie * backgroundMovie = [QTMovie movieWithFile:backgroundPath error:nil];
			flickrLayer = [QTMovieLayer layerWithMovie:backgroundMovie];
			flickrLayer.contentsGravity = kCAGravityResizeAspect;
			
			flickrLayer.frame = [[flickrWindow contentView] layer].bounds;
			
			[[[flickrWindow contentView] layer] addSublayer:flickrLayer];
		}
		
		if (loadErr)
		{
			NSLog(@"err: %@", [loadErr localizedDescription]);
		}
	}
	else
	{
		flickrLayer = [QTMovieLayer layer];
		
		flickrLayer.frame = [[flickrWindow contentView] layer].bounds;
		
		[[[flickrWindow contentView] layer] addSublayer:flickrLayer];
	}
	
	currentFlickrIndex = picIndex;
}




- (IBAction)endSlideshow:(id)sender
{
	[announcementsWindow orderOut:sender];
	announcementsWindow = nil;
	
	backgroundLayer = nil;
	titleLayer = nil;
	bodyLayer = nil;
	
	currentSlideIndex = -1;
	
	[flickrLayer removeFromSuperlayer];
	
	[flickrWindow orderOut:sender];
	flickrWindow = nil;
	
	[clockTimer invalidate], clockTimer = nil;
	[slideTimer invalidate], slideTimer = nil;
	[flickrTimer invalidate], flickrTimer = nil;
}




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
