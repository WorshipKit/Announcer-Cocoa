//
//  PCOAnnouncerController.h
//  Announcer
//
//  Created by Jason Terhorst on 5/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


#import <UIKit/UIKit.h>

#if !TARGET_OS_IPHONE
#import <Cocoa/Cocoa.h>
#endif

#import "PCOAnnouncerMainTableViewController.h"

@interface PCOAnnouncerController : NSObject
{
	UINavigationController * mainNavigationController;
	
	NSString * logoUrl;
	NSArray * announcements;
	
	NSArray * flickrImageUrls;
	
	
}

+ (NSString *)localCacheDirectoryPath;


- (UIViewController *)viewController;


- (void)loadAnnouncementsFromFeedLocation:(NSString *)feedUrl withCompletionBlock:(void (^)(void))completion andErrorBlock:(void (^)(NSError * error))error;

- (void)loadFlickrFeedFromLocation:(NSString *)feedUrl withCompletionBlock:(void (^)(void))completion andErrorBlock:(void (^)(NSError * error))errorBlock;

- (NSString *)pathForImageFileAtUrl:(NSString *)imageUrl;


@property (nonatomic, strong) NSString * logoUrl;
@property (nonatomic, strong) NSArray * announcements;

- (NSArray *)currentAnnouncements;


@property (nonatomic, strong) NSArray * flickrImageUrls;

@end
