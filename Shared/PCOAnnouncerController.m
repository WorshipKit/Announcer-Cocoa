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

@synthesize logoUrl, announcements, flickrImageUrls;

- (id)init;
{
	self = [super init];
	if (self)
	{
		//PCOAnnouncerMainTableViewController * mainTableController = [[PCOAnnouncerMainTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
		
	}
	
	return self;
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


- (void)loadAnnouncementsFromFeedLocation:(NSString *)feedUrl withCompletionBlock:(void (^)(void))completion andErrorBlock:(void (^)(NSError * error))errorBlock;
{
	dispatch_queue_t reqQueue = dispatch_queue_create("com.pco.announcer.requests", NULL);
    dispatch_async(reqQueue, ^{
		
		NSError * err = nil;
		
		NSURLResponse * response = nil;
		NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:feedUrl]];
		
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

		if ([resultsDictionary objectForKey:@"organization"])
		{
			NSDictionary * org = [resultsDictionary objectForKey:@"organization"];

			if ([org objectForKey:@"default_seconds_per_slide"])
			{
				NSNumber * seconds = [org objectForKey:@"default_seconds_per_slide"];
				NSLog(@"seconds per picture: %d", [seconds intValue]);

				[[NSUserDefaults standardUserDefaults] setObject:seconds forKey:@"seconds_per_picture"];
			}

			if ([org objectForKey:@"logo_file_url"])
			{
				logoUrl = [[org objectForKey:@"logo_file_url"] copy];
				NSLog(@"loading logo from %@", logoUrl);

				[self downloadImageFromUrl:logoUrl withCompletionBlock:^{

					NSLog(@"downloaded logo image");

				} andErrorBlock:^(NSError * error) {

					NSLog(@"error loading image: %@", [error localizedDescription]);

				}];
			}

			if ([org objectForKey:@"flickr_feed"])
			{
				NSString * flickrFeedUrl = [org objectForKey:@"flickr_feed"];
				NSLog(@"flickr feed updated: %@", flickrFeedUrl);

				[[NSUserDefaults standardUserDefaults] setObject:flickrFeedUrl forKey:@"flickr_feed_url"];
			}

			if ([org objectForKey:@"show_clock"])
			{
				NSNumber * showClock = [org objectForKey:@"show_clock"];
				if ([showClock boolValue])
				{
					NSLog(@"clock enabled");
				}
				else
				{
					NSLog(@"clock disabled");
				}

				[[NSUserDefaults standardUserDefaults] setObject:showClock forKey:@"show_clock"];
			}

			if ([org objectForKey:@"show_flickr"])
			{
				NSNumber * showFlickr = [org objectForKey:@"show_flickr"];
				if ([showFlickr boolValue])
				{
					NSLog(@"flickr enabled");
				}
				else
				{
					NSLog(@"flickr disabled");
				}

				[[NSUserDefaults standardUserDefaults] setObject:showFlickr forKey:@"show_flickr"];
			}
		}
		
		if ([resultsDictionary objectForKey:@"announcements"])
		{
			announcements = [[resultsDictionary objectForKey:@"announcements"] copy];
			
			for (NSDictionary * ann in announcements)
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


- (void)loadFlickrFeedFromLocation:(NSString *)feedUrl withCompletionBlock:(void (^)(void))completion andErrorBlock:(void (^)(NSError * error))errorBlock;
{
	
	dispatch_queue_t reqQueue = dispatch_queue_create("com.pco.announcer.requests", NULL);
    dispatch_async(reqQueue, ^{
		
		NSError * err = nil;
		
		NSURLResponse * response = nil;
		NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:feedUrl]];
		
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
				flickrImageUrls = newImageUrls;
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


@end
