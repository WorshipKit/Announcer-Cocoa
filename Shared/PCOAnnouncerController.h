//
//  PCOAnnouncerController.h
//  Announcer
//
//  Created by Jason Terhorst on 5/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//




#if !TARGET_OS_IPHONE
#import <Cocoa/Cocoa.h>
#else
#import <UIKit/UIKit.h>
#import "PCOAnnouncerMainTableViewController.h"
#endif



@interface PCOAnnouncerController : NSObject
{
	NSString * logoUrl;
	NSArray * announcements;

	NSArray * serviceTimes;
	NSArray * flickrImageUrls;
	
}

+ (NSString *)localCacheDirectoryPath;



- (void)loadAnnouncementsFromFeedLocation:(NSString *)feedUrl withCompletionBlock:(void (^)(void))completion andErrorBlock:(void (^)(NSError * error))error;

- (void)loadFlickrFeedFromLocation:(NSString *)feedUrl withCompletionBlock:(void (^)(void))completion andErrorBlock:(void (^)(NSError * error))errorBlock;

- (void)downloadImageFromUrl:(NSString *)imageUrl withCompletionBlock:(void (^)(void))completionBlock andErrorBlock:(void (^)(NSError * error))errorBlock;

- (NSString *)pathForImageFileAtUrl:(NSString *)imageUrl;


@property (nonatomic, strong) NSString * logoUrl;

@property (nonatomic, strong) NSArray * announcements;

- (NSArray *)currentAnnouncements;

@property (nonatomic, strong) NSArray * serviceTimes;
@property (nonatomic, strong) NSArray * flickrImageUrls;

@end
