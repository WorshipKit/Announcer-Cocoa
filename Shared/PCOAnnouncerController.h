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


@class PCOAnnouncerController;

@protocol PCOAnnouncerControllerDelegate <NSObject>

- (void)timeUpdated;
- (void)slideUpdated;
- (void)pictureUpdated;

@end




@interface PCOAnnouncerController : NSObject
{
	NSString * logoUrl;
	NSArray * announcements;

	NSArray * serviceTimes;
	NSArray * flickrImageUrls;


	NSTimer * clockTimer;
	NSTimer * slideTimer;
	NSInteger currentSlideIndex;
	
	NSInteger currentFlickrIndex;
	NSTimer * flickrTimer;
	
}


@property (nonatomic, assign) id<PCOAnnouncerControllerDelegate> delegate;


+ (NSString *)localCacheDirectoryPath;



- (void)loadAnnouncementsFromFeedLocation:(NSString *)feedUrl withCompletionBlock:(void (^)(void))completion andErrorBlock:(void (^)(NSError * error))error;

- (void)loadFlickrFeedFromLocation:(NSString *)feedUrl withCompletionBlock:(void (^)(void))completion andErrorBlock:(void (^)(NSError * error))errorBlock;

- (void)downloadImageFromUrl:(NSString *)imageUrl withCompletionBlock:(void (^)(void))completionBlock andErrorBlock:(void (^)(NSError * error))errorBlock;

- (NSString *)pathForImageFileAtUrl:(NSString *)imageUrl;


@property (nonatomic, strong) NSString * logoUrl;

@property (nonatomic, strong) NSString * logoPath;
@property (nonatomic, strong) NSString * currentBackgroundPath;
@property (nonatomic, strong) NSString * currentTitle;
@property (nonatomic, strong) NSString * currentBody;

@property (nonatomic, strong) NSArray * announcements;

- (NSArray *)currentAnnouncements;

@property (nonatomic, strong) NSArray * serviceTimes;
@property (nonatomic, strong) NSArray * flickrImageUrls;

@property (nonatomic, strong) NSString * currentFlickrImagePath;


- (void)showNextSlideWithCompletion:(void (^)(void))completionBlock;
- (void)showPreviousSlideWithCompletion:(void (^)(void))completionBlock;
- (void)showBigLogoWithCompletion:(void (^)(void))completionBlock;

- (void)showNextFlickrImageWithCompletion:(void (^)(void))completionBlock;
- (void)showPreviousFlickrImage:(void (^)(void))completionBlock;

- (NSString *)currentClockString;

- (BOOL)shouldShowClock;
- (void)setShouldShowClock:(BOOL)flag;

- (BOOL)shouldShowFlickr;
- (void)setShouldShowFlickr:(BOOL)flag;

- (void)allStop;


@end
