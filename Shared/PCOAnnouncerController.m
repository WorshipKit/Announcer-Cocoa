//
//  PCOAnnouncerController.m
//  Announcer
//
//  Created by Jason Terhorst on 5/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PCOAnnouncerController.h"

#import "JSONKit.h"

#import "RKXMLParserLibXML.h"

@implementation PCOAnnouncerController

- (id)init;
{
	self = [super init];
	if (self)
	{
		//PCOAnnouncerMainTableViewController * mainTableController = [[PCOAnnouncerMainTableViewController alloc] initWithStyle:UITableViewStyleGrouped];

		currentSlideIndex = -1;
		currentFlickrIndex = -1;

		_showLogo = YES;

		clockTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateClock) userInfo:nil repeats:YES];
		
		feedUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:60*5 target:self selector:@selector(autoUpdateFeed) userInfo:nil repeats:YES];
	}
	
	return self;
}


- (void)autoUpdateFeed;
{
	NSLog(@"it's been 5 minutes. auto-updating feed.");

	[self loadAnnouncementsWithCompletionBlock:^{

		NSLog(@"Loaded announcements in background.");

	} andErrorBlock:^(NSError * error) {

		NSLog(@"Error auto-loading announcements.");

	}];
	
	[self loadFlickrFeedWithCompletionBlock:^{

		NSLog(@"Loaded flickr updates in background.");

	} andErrorBlock:^(NSError * error) {

		NSLog(@"Error auto-loading flickr");

	}];
}




- (NSDate *)nextServiceTime;
{
	if ([[self serviceTimes] count] > 0)
	{
		//NSDate * activeDate = [[self serviceTimes] lastObject];
		//double secondsRemaining = [[NSDate date] timeIntervalSinceDate:activeDate] * -1;

		double threshold = 18000; // 18000 seconds in an hour

		NSDate * currentWinningDate = nil;
		double currentWinningDifference = threshold;

		for (NSDate * aDate in [self serviceTimes])
		{
			double secondsRemaining = [[NSDate date] timeIntervalSinceDate:aDate] * -1;

			if (secondsRemaining < currentWinningDifference && secondsRemaining > 0)
			{
				currentWinningDifference = secondsRemaining;
				currentWinningDate = aDate;
			}
		}

		return currentWinningDate;
	}

	return nil;
}

- (BOOL)shouldShowBigCountdown;
{
	double threshold = 301;

	NSDate * activeDate = [self nextServiceTime];
	double secondsRemaining = [[NSDate date] timeIntervalSinceDate:activeDate] * -1;

	if (secondsRemaining < threshold)
	{
		return YES;
	}

	return NO;
}

- (NSString *)currentClockString;
{
	if ([self nextServiceTime])
	{
		NSDate * activeDate = [self nextServiceTime];
		double secondsRemaining = [[NSDate date] timeIntervalSinceDate:activeDate] * -1;

		double remainder = secondsRemaining;
		int hours = remainder / 3600;
		remainder = remainder - (hours * 3600);
		int minutes = remainder / 60;
		remainder = remainder - (minutes * 60);
		//int seconds = remainder;

		NSString * seconds = [NSString stringWithFormat:@"%d", (int)remainder];
		if (remainder < 10)
		{
			seconds = [NSString stringWithFormat:@"0%d", (int)remainder];
		}

		NSString * formatString = [NSString stringWithFormat:@"%d:%d:%@", hours, minutes, seconds];
		if (hours == 0)
		{
			formatString = [NSString stringWithFormat:@"%d:%@", minutes, seconds];

			if (minutes == 0)
			{
				formatString = [NSString stringWithFormat:@"%@", seconds];
			}
		}


		if (![self shouldShowBigCountdown])
		{
			return [NSString stringWithFormat:@"Service starts in %@", formatString];
		}

		return formatString;
	}

	if ([self shouldShowClock])
	{
		NSDateFormatter *df = [[NSDateFormatter alloc] init];
		//[df setDateFormat:@"yyyy/MM/dd hh:mm:ss Z"];
		[df setDateStyle:NSDateFormatterLongStyle];
		[df setTimeStyle:NSDateFormatterLongStyle];

		return [df stringFromDate:[NSDate date]];
	}

	return @"";

}



- (BOOL)shouldShowClock;
{
	return [[[NSUserDefaults standardUserDefaults] valueForKey:@"show_clock"] boolValue];
}

- (void)setShouldShowClock:(BOOL)flag;
{
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:flag] forKey:@"show_clock"];
}

- (BOOL)shouldShowFlickr;
{
	return [[[NSUserDefaults standardUserDefaults] valueForKey:@"show_flickr"] boolValue];
}

- (void)setShouldShowFlickr:(BOOL)flag;
{
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:flag] forKey:@"show_flickr"];
}



- (void)updateClock;
{
	[self.delegate timeUpdated];
}






- (void)showBigLogoWithCompletion:(void (^)(void))completionBlock;
{
	NSInteger slideIndex = -1;
	
	NSLog(@"playing slide %ld", slideIndex);

	if (!self.logoUrl)
	{
		completionBlock();

		return;
	}

	if (![[NSFileManager defaultManager] fileExistsAtPath:self.logoPath])
	{
		if (!self.logoPath)
		{
			self.logoPath = [self pathForImageFileAtUrl:self.logoUrl];
		}

		[self downloadImageFromUrl:self.logoUrl withCompletionBlock:^{

			self.currentBackgroundPath = self.logoPath;

			completionBlock();

		} andErrorBlock:^(NSError * error) {

			self.currentBackgroundPath = nil;

			completionBlock();

		}];
	}
	else
	{
		self.currentBackgroundPath = self.logoPath;

		completionBlock();
	}

	
}


- (void)showNextSlideWithCompletion:(void (^)(void))completionBlock;
{
	[slideTimer invalidate], slideTimer = nil;

	self.currentTitle = nil;
	self.currentBody = nil;

	if ([[self currentAnnouncements] count] == 0)
	{
		// just show logo
		[self showBigLogoWithCompletion:^{

			completionBlock();
			
		}];

		return;
	}

	float slideDuration = 10;


	NSInteger slideIndex = currentSlideIndex + 1;

	if (slideIndex < 0)
	{
		slideIndex = 0;
	}

	if (slideIndex >= [[self currentAnnouncements] count])
	{
		slideIndex = 0;
	}


	NSLog(@"playing slide %ld", slideIndex);

	NSString * titleText = nil;//[[[announcerController currentAnnouncements] objectAtIndex:slideIndex] objectForKey:@"title"];
	if (![[[[self currentAnnouncements] objectAtIndex:slideIndex] objectForKey:@"title"] isEqual:[NSNull null]])
	{
		titleText = [[[self currentAnnouncements] objectAtIndex:slideIndex] objectForKey:@"title"];
	}

	self.currentTitle = titleText;

	NSString * bodyText = nil;//[[[announcerController currentAnnouncements] objectAtIndex:slideIndex] objectForKey:@"body"];
	if (![[[[self currentAnnouncements] objectAtIndex:slideIndex] objectForKey:@"body"] isEqual:[NSNull null]])
	{
		bodyText = [[[self currentAnnouncements] objectAtIndex:slideIndex] objectForKey:@"body"];
	}

	self.currentBody = bodyText;

	if ([[[self currentAnnouncements] objectAtIndex:slideIndex] objectForKey:@"duration_seconds"])
	{
		slideDuration = [[[[self currentAnnouncements] objectAtIndex:slideIndex] objectForKey:@"duration_seconds"] floatValue];
	}

	

	NSString * backgroundUrl = [[[self currentAnnouncements] objectAtIndex:slideIndex] objectForKey:@"background_file_url"];
	NSString * backgroundPath = nil;
	if ([backgroundUrl isKindOfClass:[NSString class]])
	{
		backgroundPath = [self pathForImageFileAtUrl:backgroundUrl];
	}

	if (![[NSFileManager defaultManager] fileExistsAtPath:backgroundPath])
	{
		[self downloadImageFromUrl:backgroundUrl withCompletionBlock:^{

			self.currentBackgroundPath = backgroundPath;

			completionBlock();

		} andErrorBlock:^(NSError * err) {

			self.currentBackgroundPath = nil;

			completionBlock();
		}];
	}
	else
	{
		self.currentBackgroundPath = backgroundPath;

		completionBlock();
	}



	_showLogo = ![[[[self currentAnnouncements] objectAtIndex:slideIndex] objectForKey:@"show_logo"] boolValue];
	if (_showLogo)
	{
		NSLog(@"showing logo");
	}
	else
	{
		NSLog(@"dont' show logo");
	}


	currentSlideIndex = slideIndex;
	
	slideTimer = [NSTimer scheduledTimerWithTimeInterval:slideDuration target:self selector:@selector(nextSlide) userInfo:nil repeats:NO];

	
}

- (void)showPreviousSlideWithCompletion:(void (^)(void))completionBlock;
{
	[slideTimer invalidate], slideTimer = nil;

	if ([[self currentAnnouncements] count] == 0)
	{
		// just show logo
		[self showBigLogoWithCompletion:^{

			completionBlock();

		}];

		return;
	}

	int slideDuration = 10;

	

	slideTimer = [NSTimer scheduledTimerWithTimeInterval:slideDuration target:self selector:@selector(nextSlide) userInfo:nil repeats:NO];

	completionBlock();
}



- (void)showNextFlickrImageWithCompletion:(void (^)(void))completionBlock;
{
	[flickrTimer invalidate], flickrTimer = nil;


	NSInteger picIndex = currentFlickrIndex + 1;

	if (picIndex < 0)
	{
		picIndex = 0;
	}

	if (picIndex >= [[self flickrImageUrls] count])
	{
		picIndex = 0;
	}


	NSString * backgroundUrl = [[self flickrImageUrls] objectAtIndex:picIndex];
	NSString * backgroundPath = nil;
	if ([backgroundUrl isKindOfClass:[NSString class]])
	{
		backgroundPath = [self pathForImageFileAtUrl:backgroundUrl];
	}

	currentFlickrIndex = picIndex;


	float secondsPerPicture = 10;
	if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"seconds_per_picture"] floatValue] > 0)
	{
		secondsPerPicture = [[[NSUserDefaults standardUserDefaults] valueForKey:@"seconds_per_picture"] floatValue];
	}

	flickrTimer = [NSTimer scheduledTimerWithTimeInterval:secondsPerPicture target:self selector:@selector(nextPicture) userInfo:nil repeats:YES];
}

- (void)showPreviousFlickrImage:(void (^)(void))completionBlock;
{
	[flickrTimer invalidate], flickrTimer = nil;




	float secondsPerPicture = 10;
	if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"seconds_per_picture"] floatValue] > 0)
	{
		secondsPerPicture = [[[NSUserDefaults standardUserDefaults] valueForKey:@"seconds_per_picture"] floatValue];
	}

	flickrTimer = [NSTimer scheduledTimerWithTimeInterval:secondsPerPicture target:self selector:@selector(nextPicture) userInfo:nil repeats:YES];
}



- (void)nextSlide;
{
	[self showNextSlideWithCompletion:^{

		[self.delegate slideUpdated];

	}];

	if (!clockTimer)
	{
		clockTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateClock) userInfo:nil repeats:YES];
	}
}

- (void)nextPicture;
{
	[self showNextFlickrImageWithCompletion:^{

		[self.delegate pictureUpdated];

	}];
}


- (void)allStop;
{
	[clockTimer invalidate], clockTimer = nil;
	[slideTimer invalidate], slideTimer = nil;
	[flickrTimer invalidate], flickrTimer = nil;

	currentSlideIndex = -1;
}



+ (NSString *)localCacheDirectoryPath;
{
	NSString* path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	
	path = [path stringByAppendingPathComponent:@"Announcer"];
	
	return path;
}



- (NSArray *)currentAnnouncements;
{
	NSMutableArray * current = [NSMutableArray array];
	
	for (NSDictionary * ann in self.announcements)
	{
		NSDate * startDate = nil;//[ann objectForKey:@"start_date"];
		if (![[ann objectForKey:@"start_date"] isKindOfClass:[NSNull class]])
		{
			NSDateFormatter *df = [[NSDateFormatter alloc] init];
			[df setDateFormat:@"yyyyMM/dd hh:mm:ss Z"];
			startDate = [df dateFromString: [ann objectForKey:@"start_date"]];
		}
		
		NSDate * expDate = nil;//[ann objectForKey:@"expiration_date"];
		if (![[ann objectForKey:@"expiration"] isKindOfClass:[NSNull class]])
		{
			NSDateFormatter *df = [[NSDateFormatter alloc] init];
			[df setDateFormat:@"yyyy/MM/dd hh:mm:ss Z"];
			expDate = [df dateFromString: [ann objectForKey:@"expiration"]];
		}
		
		if (startDate)
		{
			//NSLog(@"start: %@", startDate);
		}
		
		if (expDate)
		{
			//NSLog(@"exp: %@", expDate);
			//NSLog(@"exp diff: %f", [expDate timeIntervalSince1970]);
		}
		
		if (!startDate)
		{
			if (expDate)
			{
				if ([expDate timeIntervalSince1970] > [[NSDate date] timeIntervalSince1970])
				{
					[current addObject:ann];
				}
			}
			else
			{
				[current addObject:ann];
			}
		}
		else if (!expDate)
		{
			if (startDate)
			{
				if ([startDate timeIntervalSince1970] < [[NSDate date] timeIntervalSince1970])
				{
					[current addObject:ann];
				}
			}
			else
			{
				[current addObject:ann];
			}
		}
		else
		{
			[current addObject:ann];
		}
	}
	
	return current;
}



- (void)downloadImageFromUrl:(NSString *)imageUrl withCompletionBlock:(void (^)(void))completionBlock andErrorBlock:(void (^)(NSError * error))errorBlock;
{
	dispatch_queue_t reqQueue = dispatch_queue_create("com.pco.announcer.imagedownloads", NULL);
    dispatch_async(reqQueue, ^{
		
		NSError * err = nil;
		
		NSURLResponse * response = nil;
		NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:imageUrl]];
		
		NSData* imageData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&err];
		
		if (err)
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				
				errorBlock(err);
				
				dispatch_release(reqQueue); //this executes on main thread
				
			});
			
			return;
		}
		
		if (!imageData)
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				
				errorBlock([NSError errorWithDomain:@"Invalid data" code:0 userInfo:nil]);
				
				dispatch_release(reqQueue); //this executes on main thread
				
			});
			
			return;
		}
		
		if (![[NSFileManager defaultManager] fileExistsAtPath:[PCOAnnouncerController localCacheDirectoryPath]])
		{
			[[NSFileManager defaultManager] createDirectoryAtPath:[PCOAnnouncerController localCacheDirectoryPath] withIntermediateDirectories:YES attributes:nil error:nil];
			
		}
		
		NSLog(@"saving to %@", [self pathForImageFileAtUrl:imageUrl]);
		
		if (![imageData writeToFile:[self pathForImageFileAtUrl:imageUrl] atomically:YES])
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				
				errorBlock([NSError errorWithDomain:@"Unable to save image file" code:0 userInfo:nil]);
				
				dispatch_release(reqQueue); //this executes on main thread
				
			});
			
			return;
		}
		else
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				
				completionBlock();
				
				dispatch_release(reqQueue); //this executes on main thread
				
			});
			
		}
		
	});
	
	
}


- (NSString *)pathForImageFileAtUrl:(NSString *)imageUrl;
{
	return [[PCOAnnouncerController localCacheDirectoryPath] stringByAppendingPathComponent:[imageUrl lastPathComponent]];
}


- (void)loadLogoWithCompletionBlock:(void (^)(void))completion andErrorBlock:(void (^)(NSError * err))errorBlock
{
	if (![[NSFileManager defaultManager] fileExistsAtPath:self.logoPath])
	{
		if (!self.logoPath)
		{
			self.logoPath = [self pathForImageFileAtUrl:self.logoUrl];
		}

		[self downloadImageFromUrl:self.logoUrl withCompletionBlock:^{

			self.currentBackgroundPath = self.logoPath;

			completion();

		} andErrorBlock:^(NSError * error) {

			self.currentBackgroundPath = nil;

			errorBlock(error);

		}];
	}
	else
	{
		self.currentBackgroundPath = self.logoPath;

		completion();
	}
}

- (void)loadAnnouncementsWithCompletionBlock:(void (^)(void))completion andErrorBlock:(void (^)(NSError * error))errorBlock;
{
	dispatch_queue_t reqQueue = dispatch_queue_create("com.pco.announcer.requests", NULL);
    dispatch_async(reqQueue, ^{
		
		NSError * err = nil;
		
		NSURLResponse * response = nil;
		NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.announcementsFeedUrl]];
		
		NSData* jsonData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&err];
		
		if (err)
		{
			
			dispatch_async(dispatch_get_main_queue(), ^{
				
				errorBlock(err);
				
				dispatch_release(reqQueue); //this executes on main thread
				
			});
			
			
			return;
		}
		
		if (!jsonData)
		{
			
			dispatch_async(dispatch_get_main_queue(), ^{
				
				errorBlock([NSError errorWithDomain:@"Invalid data" code:0 userInfo:nil]);
				
				dispatch_release(reqQueue); //this executes on main thread
				
			});
			
			return;
		}
		
		NSDictionary *resultsDictionary = [jsonData objectFromJSONData];

		NSLog(@"result: %@", resultsDictionary);

		if ([resultsDictionary objectForKey:@"campus"])
		{
			NSDictionary * campus = [resultsDictionary objectForKey:@"campus"];

			if ([campus objectForKey:@"default_seconds_per_slide"])
			{
				NSNumber * seconds = [campus objectForKey:@"default_seconds_per_slide"];
				NSLog(@"seconds per picture: %d", [seconds intValue]);

				[[NSUserDefaults standardUserDefaults] setObject:seconds forKey:@"seconds_per_picture"];
			}

			if ([campus objectForKey:@"logo_file_url"])
			{
				NSString * newLogo = [campus objectForKey:@"logo_file_url"];

				dispatch_async(dispatch_get_main_queue(), ^{

					self.logoUrl = newLogo;

					NSLog(@"loading logo from %@", _logoUrl);

					[self downloadImageFromUrl:_logoUrl withCompletionBlock:^{

						NSLog(@"downloaded logo image");

						self.logoPath = [self pathForImageFileAtUrl:self.logoUrl];

					} andErrorBlock:^(NSError * error) {

						NSLog(@"error loading image: %@", [error localizedDescription]);
						
					}];

				});
			}

			if ([campus objectForKey:@"flickr_feed"])
			{
				NSString * flickrFeedUrl = [campus objectForKey:@"flickr_feed"];
				NSLog(@"flickr feed updated: %@", flickrFeedUrl);

				[[NSUserDefaults standardUserDefaults] setObject:flickrFeedUrl forKey:@"flickr_feed_url"];
			}

			if ([campus objectForKey:@"show_clock"])
			{
				NSNumber * showClock = [campus objectForKey:@"show_clock"];
				if ([showClock boolValue])
				{
					NSLog(@"clock enabled");
				}
				else
				{
					NSLog(@"clock disabled");
				}

				if (showClock)
					[[NSUserDefaults standardUserDefaults] setObject:showClock forKey:@"show_clock"];
			}

			if ([campus objectForKey:@"show_flickr"])
			{
				NSNumber * showFlickr = [campus objectForKey:@"show_flickr"];
				if ([showFlickr boolValue])
				{
					NSLog(@"flickr enabled");
				}
				else
				{
					NSLog(@"flickr disabled");
				}

				if (showFlickr)
					[[NSUserDefaults standardUserDefaults] setObject:showFlickr forKey:@"show_flickr"];
			}
		}
		
		if ([resultsDictionary objectForKey:@"service_times"])
		{
			NSArray * rawTimes = [resultsDictionary objectForKey:@"service_times"];

			NSMutableArray * parsedTimes = [NSMutableArray array];

			NSLog(@"current day of week: %ld", [self dayOfWeek]);

			for (NSDictionary * time in rawTimes)
			{
				int day = [[time valueForKey:@"day"] intValue];
				int hour = [[time valueForKey:@"hour"] intValue];
				int minute = [[time valueForKey:@"minute"] intValue];



				if (day == [self dayOfWeek] || day == [self tomorrowDayOfWeek])
				{
					unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
					NSDate *date = [NSDate date];
					if (day == [self tomorrowDayOfWeek])
					{
						date = [date dateByAddingTimeInterval:18400];
					}
					NSCalendar *calendar = [NSCalendar currentCalendar];
					[calendar setTimeZone:[NSTimeZone localTimeZone]];
					NSDateComponents *comps = [calendar components:unitFlags fromDate:date];
					
					//update for the start date
					[comps setHour:hour];
					[comps setMinute:minute];
					[comps setSecond:0];
					NSDate *sDate = [calendar dateFromComponents:comps];

					NSDateFormatter *df = [[NSDateFormatter alloc] init];
					//[df setDateFormat:@"yyyy/MM/dd hh:mm:ss Z"];
					[df setDateStyle:NSDateFormatterLongStyle];
					[df setTimeStyle:NSDateFormatterLongStyle];
					[df setTimeZone:[NSTimeZone localTimeZone]];

					NSLog(@"adding date: %@", [df stringFromDate:sDate]);

					[parsedTimes addObject:sDate];
				}
			}

			dispatch_async(dispatch_get_main_queue(), ^{

				NSLog(@"times: %@", parsedTimes);

				self.serviceTimes = parsedTimes;

			});
		}
		
		if ([resultsDictionary objectForKey:@"announcements"])
		{
			NSArray * newAnnouncements = [resultsDictionary objectForKey:@"announcements"];
			
			for (NSDictionary * ann in newAnnouncements)
			{
				if ([ann objectForKey:@"background_file_url"] && ![[ann objectForKey:@"background_file_url"] isEqual:[NSNull null]])
				{
					[self downloadImageFromUrl:[ann objectForKey:@"background_file_url"] withCompletionBlock:^{
						
						NSLog(@"downloaded image");
						
					} andErrorBlock:^(NSError * error) {
						
						NSLog(@"error downloading image: %@", [err localizedDescription]);
						
					}];
				}
			}
			
			dispatch_async(dispatch_get_main_queue(), ^{

				self.announcements = newAnnouncements;

				completion();
				
				dispatch_release(reqQueue); //this executes on main thread
				
			});
			
			
			return;
		}
		else
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				
				errorBlock([NSError errorWithDomain:@"No announcements" code:0 userInfo:nil]);
				
				dispatch_release(reqQueue); //this executes on main thread
				
			});
			
			return;
		}
		
	});
	
}


- (void)loadFlickrFeedWithCompletionBlock:(void (^)(void))completion andErrorBlock:(void (^)(NSError * error))errorBlock;
{
	
	dispatch_queue_t reqQueue = dispatch_queue_create("com.pco.announcer.requests", NULL);
    dispatch_async(reqQueue, ^{
		
		NSError * err = nil;
		
		NSURLResponse * response = nil;
		NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.flickrFeedUrl]];
		
		NSData* jsonData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&err];
		
		if (err)
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				
				errorBlock(err);
				
				dispatch_release(reqQueue); //this executes on main thread
				
			});
			
			return;
		}
		
		if (!jsonData)
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				
				errorBlock([NSError errorWithDomain:@"Invalid data" code:0 userInfo:nil]);
				
				dispatch_release(reqQueue); //this executes on main thread
				
			});
			
			return;
		}
		
		NSString * jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
		
		RKXMLParserLibXML * parser = [[RKXMLParserLibXML alloc] init];
		
		NSDictionary *resultsDictionary = [parser parseXML:jsonString];
		
		/*
		 if ([resultsDictionary objectForKey:@"announcements"])
		 {
		 announcements = [[resultsDictionary objectForKey:@"announcements"] copy];
		 
		 completion();
		 }
		 else
		 {
		 errorBlock([NSError errorWithDomain:@"No announcements" code:0 userInfo:nil]);
		 }
		 */
		
		if (!resultsDictionary)
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				
				errorBlock([NSError errorWithDomain:@"Invalid XML" code:0 userInfo:nil]);
				
				dispatch_release(reqQueue); //this executes on main thread
				
			});
			
			return;
		}
		
		NSMutableArray * newImageUrls = [NSMutableArray array];
		
		if ([[[resultsDictionary objectForKey:@"rss"] objectForKey:@"channel"] objectForKey:@"item"])
		{
			//NSLog(@"items: %@", NSStringFromClass([[[resultsDictionary objectForKey:@"rss"] objectForKey:@"channel"] objectForKey:@"item"]));
			
			//NSLog(@"object count: %lu", [[[[resultsDictionary objectForKey:@"rss"] objectForKey:@"channel"] objectForKey:@"item"] count]);
			
			for (NSDictionary * item in [[[resultsDictionary objectForKey:@"rss"] objectForKey:@"channel"] objectForKey:@"item"])
			{
				//NSLog(@"item content: %@", [[item objectForKey:@"content"] objectForKey:@"url"]);
				
				[newImageUrls addObject:[[item objectForKey:@"content"] objectForKey:@"url"]];
				
				[self downloadImageFromUrl:[[item objectForKey:@"content"] objectForKey:@"url"] withCompletionBlock:^{
					NSLog(@"image downloaded");
				} andErrorBlock:^(NSError * error) {
					NSLog(@"error loading image: %@", [error localizedDescription]);
				}];
			}
			
			if ([newImageUrls count] > 0)
			{
				_flickrImageUrls = newImageUrls;
			}
			
			dispatch_async(dispatch_get_main_queue(), ^{
				
				completion();
				
				dispatch_release(reqQueue); //this executes on main thread
				
			});
			
			return;
		}
		else
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				
				errorBlock([NSError errorWithDomain:@"Invalid feed" code:0 userInfo:nil]);
				
				dispatch_release(reqQueue); //this executes on main thread
				
			});
			
			return;
		}
		
		
		//NSLog(@"results: %@", resultsDictionary);
		
	});
	
}



- (NSInteger)dayOfWeek;
{
	NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];

	NSDateComponents * weekdayComponents = [gregorian components:NSWeekdayCalendarUnit fromDate:[NSDate date]];

	NSInteger weekday = [weekdayComponents weekday] - 1;
	// weekday 1 = Sunday for Gregorian calendar

	return weekday;
}

- (NSInteger)tomorrowDayOfWeek;
{
	NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];

	NSDateComponents * weekdayComponents = [gregorian components:NSWeekdayCalendarUnit fromDate:[[NSDate date] dateByAddingTimeInterval:86400]];

	NSInteger weekday = [weekdayComponents weekday] - 1;
	// weekday 1 = Sunday for Gregorian calendar

	return weekday;
}


@end
