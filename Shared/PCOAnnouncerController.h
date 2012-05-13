//
//  PCOAnnouncerController.h
//  Announcer
//
//  Created by Jason Terhorst on 5/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

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


@property (nonatomic, strong) NSString * logoUrl;
@property (nonatomic, strong) NSArray * announcements;

@property (nonatomic, strong) NSArray * flickrImageUrls;

@end
