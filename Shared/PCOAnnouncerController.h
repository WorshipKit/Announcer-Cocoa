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


	NSTimer * feedUpdateTimer;
	
	NSTimer * clockTimer;
	NSTimer * slideTimer;
	NSInteger currentSlideIndex;
	
	NSInteger currentFlickrIndex;
	NSTimer * flickrTimer;
	
}


@property (nonatomic, assign) id<PCOAnnouncerControllerDelegate> delegate;


+ (NSString *)localCacheDirectoryPath;



@property (nonatomic, strong) NSString * announcementsFeedUrl;
@property (nonatomic, strong) NSString * flickrFeedUrl;


- (void)loadLogoWithCompletionBlock:(void (^)(void))completion andErrorBlock:(void (^)(NSError * error))error;

- (void)loadAnnouncementsWithCompletionBlock:(void (^)(void))completion andErrorBlock:(void (^)(NSError * error))error;

- (void)loadFlickrFeedWithCompletionBlock:(void (^)(void))completion andErrorBlock:(void (^)(NSError * error))errorBlock;

- (void)downloadImageFromUrl:(NSString *)imageUrl withCompletionBlock:(void (^)(void))completionBlock andErrorBlock:(void (^)(NSError * error))errorBlock;

- (NSString *)pathForImageFileAtUrl:(NSString *)imageUrl;


@property (nonatomic, strong) NSString * logoUrl;

@property (nonatomic, strong) NSString * logoPath;
@property (nonatomic, strong) NSString * currentBackgroundPath;
@property (nonatomic, strong) NSString * currentTitle;
@property (nonatomic, strong) NSString * currentBody;
@property (nonatomic, assign) BOOL showLogo;

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


- (BOOL)shouldShowBigCountdown;

- (BOOL)shouldShowClock;
- (void)setShouldShowClock:(BOOL)flag;

- (BOOL)shouldShowFlickr;
- (void)setShouldShowFlickr:(BOOL)flag;

- (void)allStop;


@end
